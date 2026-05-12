output "lambda_function_name" {
  value = aws_lambda_function.yt_lambda.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.yt_lambda.arn
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.yt_lambda.invoke_arn
}