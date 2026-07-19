"""Tests for silver_to_gold_analytics.py transforms."""
from pyspark.sql import types as T
import pytest


def test_add_category_name(spark, silver_to_gold_module):
    module = silver_to_gold_module
    
    stats_schema = T.StructType([
        T.StructField('category_id', T.LongType()),
        T.StructField('region', T.StringType()),
        T.StructField('video_id', T.StringType()),
        T.StructField('views', T.LongType()),
    ])
    stats_data = [(10, 'us', 'vid_1', 100), (20, 'us', 'vid_2', 200)]
    stats_df = spark.createDataFrame(stats_data, stats_schema)
    
    ref_schema = T.StructType([
        T.StructField('id', T.StringType()),
        T.StructField('snippet_title', T.StringType()),
        T.StructField('region', T.StringType()),
    ])
    ref_data = [('10', 'Music', 'us'), ('20', 'Sports', 'us')]
    ref_df = spark.createDataFrame(ref_data, ref_schema)
    
    result_df = module.add_category_name(stats_df, ref_df)
    
    assert 'category_name' in result_df.columns
    assert result_df.filter(result_df.category_name == 'Music').count() == 1
    assert result_df.filter(result_df.category_name == 'Sports').count() == 1


def test_add_category_name_falls_back_to_unknown(spark, silver_to_gold_module):
    module = silver_to_gold_module
    
    stats_schema = T.StructType([
        T.StructField('category_id', T.LongType()),
        T.StructField('region', T.StringType()),
        T.StructField('video_id', T.StringType()),
        T.StructField('views', T.LongType()),
    ])
    stats_data = [(999, 'us', 'vid_1', 100)]
    stats_df = spark.createDataFrame(stats_data, stats_schema)
    
    ref_schema = T.StructType([
        T.StructField('id', T.StringType()),
        T.StructField('snippet_title', T.StringType()),
        T.StructField('region', T.StringType()),
    ])
    ref_data = [('10', 'Music', 'us')]
    ref_df = spark.createDataFrame(ref_data, ref_schema)
    
    result_df = module.add_category_name(stats_df, ref_df)
    
    assert 'Unknown Category 999' in result_df.select('category_name').collect()[0][0]


def test_build_trending_analytics(spark, silver_to_gold_module):
    module = silver_to_gold_module
    from datetime import date
    
    schema = 'video_id string, region string, trending_date_parsed date, views long, likes long, dislikes long, comment_count long, like_ratio double, engagement_rate double, channel_title string, category_id long'
    data = [('v1', 'us', date(2024, 7, 17), 100, 10, 1, 5, 0.1, 0.16, 'Chan1', 10)]
    df = spark.createDataFrame(data, schema)
    
    result_df = module.build_trending_analytics(df)
    
    assert result_df.count() == 1
    assert 'total_videos' in result_df.columns
    assert 'total_views' in result_df.columns
    assert 'avg_like_ratio' in result_df.columns
    assert '_aggregated_at' in result_df.columns


def test_build_channel_analytics_has_ranking(spark, silver_to_gold_module):
    module = silver_to_gold_module
    from datetime import date
    
    schema = 'video_id string, region string, channel_title string, trending_date_parsed date, category_name string, views long, likes long, comment_count long, engagement_rate double'
    data = [
        ('v1', 'us', 'ChanA', date(2024, 7, 17), 'Music', 300, 30, 15, 0.15),
        ('v2', 'us', 'ChanB', date(2024, 7, 17), 'Sports', 100, 10, 5, 0.15),
    ]
    df = spark.createDataFrame(data, schema)
    
    result_df = module.build_channel_analytics(df)
    
    assert result_df.count() == 2
    assert 'rank_in_region' in result_df.columns
    row_a = result_df.filter(result_df.channel_title == 'ChanA').collect()[0]
    row_b = result_df.filter(result_df.channel_title == 'ChanB').collect()[0]
    assert row_a.rank_in_region == 1  # highest views
    assert row_b.rank_in_region == 2


def test_build_category_analytics_calculates_view_share(spark, silver_to_gold_module):
    module = silver_to_gold_module
    from datetime import date
    
    schema = 'video_id string, region string, category_name string, category_id long, channel_title string, trending_date_parsed date, views long, likes long, comment_count long, engagement_rate double'
    data = [
        ('v1', 'us', 'Music', 10, 'Chan1', date(2024, 7, 17), 300, 30, 15, 0.15),
        ('v2', 'us', 'Sports', 20, 'Chan2', date(2024, 7, 17), 100, 10, 5, 0.15),
    ]
    df = spark.createDataFrame(data, schema)
    
    result_df = module.build_category_analytics(df)
    
    assert result_df.count() == 2
    assert 'view_share_pct' in result_df.columns
    music_share = result_df.filter(result_df.category_name == 'Music').select('view_share_pct').collect()[0][0]
    assert music_share == 75.0  # 300 / 400 * 100