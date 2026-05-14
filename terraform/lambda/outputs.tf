output "youtube_api_integstion_function_name" {
  value = aws_lambda_function.youtube_api_integstion_function.function_name
}

output "youtube_api_integstion_function_arn" {
  value = aws_lambda_function.youtube_api_integstion_function.arn
}

output "youtube_api_integstion_function_invoke_arn" {
  value = aws_lambda_function.youtube_api_integstion_function.invoke_arn
}

output "json_to_parquet_function_name" {
  value = aws_lambda_function.json_to_parquet_function.function_name
}

output "json_to_parquet_function_arn" {
  value = aws_lambda_function.json_to_parquet_function.arn
}

output "json_to_parquet_function_invoke_arn" {
  value = aws_lambda_function.json_to_parquet_function.invoke_arn
}