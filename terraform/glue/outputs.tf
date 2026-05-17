output "bronze_database_name" {
  value = aws_glue_catalog_database.bronze_db.name
}

output "silver_database_name" {
  value = aws_glue_catalog_database.silver_db.name
}

output "gold_database_name" {
  value = aws_glue_catalog_database.gold_db.name
}

output "bronze_crawler_name" {
  value = aws_glue_crawler.bronze_crawler.name
}

output "bronze_crawler_arn" {
  value = aws_glue_crawler.bronze_crawler.arn
}

output "bronze_to_silver_statistics_glue_job_name" {
  value = aws_glue_job.bronze_to_silver_statistics_glue_job.name
}

output "bronze_to_silver_statistics_glue_job_arn" {
  value = aws_glue_job.bronze_to_silver_statistics_glue_job.arn
}

output "silver_to_gold_statistics_glue_job_name" {
  value = aws_glue_job.silver_to_gold_statistics_glue_job.name
}

output "silver_to_gold_statistics_glue_job_arn" {
  value = aws_glue_job.silver_to_gold_statistics_glue_job.arn
}

output "bronze_to_silver_statistics_glue_script_s3_key" {
  value = aws_s3_object.bronze_to_silver_statistics_glue_script.key
}

output "bronze_to_silver_statistics_glue_script_s3_uri" {
  value = "s3://${aws_s3_object.bronze_to_silver_statistics_glue_script.bucket}/${aws_s3_object.bronze_to_silver_statistics_glue_script.key}"
}

output "silver_to_gold_analytics_glue_script_s3_key" {
  value = aws_s3_object.silver_to_gold_analytics_glue_script.key
}

output "silver_to_gold_analytics_glue_script_s3_uri" {
  value = "s3://${aws_s3_object.silver_to_gold_analytics_glue_script.bucket}/${aws_s3_object.silver_to_gold_analytics_glue_script.key}"
}