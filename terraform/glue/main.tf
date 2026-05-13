#################################################
# Bronze Database
#################################################

resource "aws_glue_catalog_database" "bronze_db" {
  name        = "yt-pipeline-bronze-dev"
  description = "yt pipeline - raw data"
}

#################################################
# Silver Database
#################################################

resource "aws_glue_catalog_database" "silver_db" {
  name        = "yt-pipeline-silver-dev"
  description = "yt pipeline - cleansed data"
}

#################################################
# Gold Database
#################################################

resource "aws_glue_catalog_database" "gold_db" {
  name        = "yt-pipeline-gold-dev"
  description = "yt pipeline - analytics aggregation"
}