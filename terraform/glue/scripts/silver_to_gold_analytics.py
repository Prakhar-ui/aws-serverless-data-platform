import sys
from pyspark.sql import DataFrame
from pyspark.sql import functions as F
from pyspark.sql.window import Window

# ── Transformation Functions (Testable locally with pure PySpark) ────────────

def add_category_name(df: DataFrame, reference_df: DataFrame) -> DataFrame:
    """Joins the category reference table (ingested from the YouTube videoCategories
    API and flattened by the json_to_parquet Lambda) onto the statistics data to
    attach a real, human-readable category_name.

    Category IDs are global but the reference data is stored per-region, so we join
    on (category_id, region) and fall back to a labeled placeholder only when a
    region genuinely has no matching category (e.g. a brand-new category ID YouTube
    hasn't backfilled reference data for yet).

    The reference table is tiny (< 1k rows) so we broadcast it to avoid a full shuffle.
    """
    from pyspark.sql.functions import broadcast

    ref = broadcast(
        reference_df
        .select(
            F.col("id").cast("long").alias("category_id"),
            F.col("snippet_title").alias("category_name"),
            F.col("region").alias("ref_region"),
        )
        .dropDuplicates(["category_id", "ref_region"])
    )

    df = df.join(
        ref,
        on=(df["category_id"] == ref["category_id"]) & (df["region"] == ref["ref_region"]),
        how="left",
    ).drop(ref["category_id"]).drop("ref_region")

    df = df.withColumn(
        "category_name",
        F.coalesce(
            F.col("category_name"),
            F.concat(F.lit("Unknown Category "), F.col("category_id").cast("string")),
        )
    )

    return df


def build_trending_analytics(df: DataFrame) -> DataFrame:
    """Builds daily trending summaries per region."""
    trending = df.groupBy("region", "trending_date_parsed").agg(
        F.count("video_id").alias("total_videos"),
        F.sum("views").alias("total_views"),
        F.sum("likes").alias("total_likes"),
        F.sum("dislikes").alias("total_dislikes"),
        F.sum("comment_count").alias("total_comments"),
        F.avg("views").alias("avg_views_per_video"),
        F.avg("like_ratio").alias("avg_like_ratio"),
        F.avg("engagement_rate").alias("avg_engagement_rate"),
        F.max("views").alias("max_views"),
        F.countDistinct("channel_title").alias("unique_channels"),
        F.countDistinct("category_id").alias("unique_categories"),
    )
    return trending.withColumn("_aggregated_at", F.current_timestamp())


def build_channel_analytics(df: DataFrame) -> DataFrame:
    """Builds channel performance metrics ranked by regional views."""
    channel = df.groupBy("channel_title", "region").agg(
        F.countDistinct("video_id").alias("total_videos"),
        F.sum("views").alias("total_views"),
        F.sum("likes").alias("total_likes"),
        F.sum("comment_count").alias("total_comments"),
        F.avg("views").alias("avg_views_per_video"),
        F.avg("engagement_rate").alias("avg_engagement_rate"),
        F.max("views").alias("peak_views"),
        F.count("trending_date_parsed").alias("times_trending"),
        F.min("trending_date_parsed").alias("first_trending"),
        F.max("trending_date_parsed").alias("last_trending"),
        F.collect_set("category_name").alias("categories"),
    )

    window_rank = Window.partitionBy("region").orderBy(F.col("total_views").desc())
    channel = channel.withColumn("rank_in_region", F.row_number().over(window_rank))
    
    return channel.withColumn("_aggregated_at", F.current_timestamp())


def build_category_analytics(df: DataFrame) -> DataFrame:
    """Builds category-level trends over time including view share percentage."""
    category = df.groupBy("category_name", "category_id", "region", "trending_date_parsed").agg(
        F.count("video_id").alias("video_count"),
        F.sum("views").alias("total_views"),
        F.sum("likes").alias("total_likes"),
        F.sum("comment_count").alias("total_comments"),
        F.avg("engagement_rate").alias("avg_engagement_rate"),
        F.countDistinct("channel_title").alias("unique_channels"),
    )

    window_total = Window.partitionBy("region", "trending_date_parsed")
    category = category.withColumn(
        "view_share_pct",
        F.round(F.col("total_views") / F.sum("total_views").over(window_total) * 100, 2)
    )
    
    return category.withColumn("_aggregated_at", F.current_timestamp())


# ── Main Execution (Glue I/O) ────────────────────────────────────────────────
# Wrapping the execution logic prevents Glue libraries from executing 
# when you import this file in your unit tests.

if __name__ == "__main__":
    from awsglue.utils import getResolvedOptions
    from pyspark.context import SparkContext
    from awsglue.context import GlueContext
    from awsglue.job import Job
    from awsglue.dynamicframe import DynamicFrame

    # Job Setup
    args = getResolvedOptions(sys.argv, [
        "JOB_NAME",
        "silver_database",
        "gold_bucket",
        "gold_database",
        "reference_table",
    ])

    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)
    logger = glueContext.get_logger()

    SILVER_DB = args["silver_database"]
    GOLD_BUCKET = args["gold_bucket"]
    GOLD_DB = args["gold_database"]

    # 1. Read Silver Table
    logger.info("Reading Silver layer tables...")
    stats_dyf = glueContext.create_dynamic_frame.from_catalog(
        database=SILVER_DB,
        table_name="clean_statistics",
        transformation_ctx="stats",
    )
    stats_df = stats_dyf.toDF()
    logger.info(f"Statistics records: {stats_df.count()}")

    logger.info(f"Reading Silver reference table: {args['reference_table']}...")
    reference_dyf = glueContext.create_dynamic_frame.from_catalog(
        database=SILVER_DB,
        table_name=args["reference_table"],
        transformation_ctx="reference",
    )
    reference_df = reference_dyf.toDF()
    logger.info(f"Reference records: {reference_df.count()}")

    # 2. Apply Transformations
    stats_df = add_category_name(stats_df, reference_df)
    
    trending_df = build_trending_analytics(stats_df)
    channel_df = build_channel_analytics(stats_df)
    category_df = build_category_analytics(stats_df)

    # 3. Write Gold Tables
    def write_to_gold(df: DataFrame, table_name: str, path: str):
        dyf = DynamicFrame.fromDF(df, glueContext, table_name)
        sink = glueContext.getSink(
            connection_type="s3",
            path=path,
            enableUpdateCatalog=True,
            updateBehavior="UPDATE_IN_DATABASE",
            partitionKeys=["region"],
        )
        sink.setCatalogInfo(catalogDatabase=GOLD_DB, catalogTableName=table_name)
        sink.setFormat("glueparquet", compression="snappy")
        sink.writeFrame(dyf)
        logger.info(f"  Written {df.count()} rows → {path}")

    logger.info("Building Gold: trending_analytics...")
    write_to_gold(trending_df, "trending_analytics", f"s3://{GOLD_BUCKET}/youtube/trending_analytics/")

    logger.info("Building Gold: channel_analytics...")
    write_to_gold(channel_df, "channel_analytics", f"s3://{GOLD_BUCKET}/youtube/channel_analytics/")

    logger.info("Building Gold: category_analytics...")
    write_to_gold(category_df, "category_analytics", f"s3://{GOLD_BUCKET}/youtube/category_analytics/")

    logger.info("Gold layer build complete.")
    job.commit()