#################################################
# Bronze Database
#################################################

resource "aws_glue_catalog_database" "bronze_db" {
  name        = "yt_pipeline_bronze_dev"
  description = "yt pipeline - raw data"
}

#################################################
# Silver Database
#################################################

resource "aws_glue_catalog_database" "silver_db" {
  name        = "yt_pipeline_silver_dev"
  description = "yt pipeline - cleansed data"
}

#################################################
# Gold Database
#################################################

resource "aws_glue_catalog_database" "gold_db" {
  name        = "yt_pipeline_gold_dev"
  description = "yt pipeline - analytics aggregation"
}