output "bronze_database_name" {
  value = aws_glue_catalog_database.bronze_db.name
}

output "silver_database_name" {
  value = aws_glue_catalog_database.silver_db.name
}

output "gold_database_name" {
  value = aws_glue_catalog_database.gold_db.name
}