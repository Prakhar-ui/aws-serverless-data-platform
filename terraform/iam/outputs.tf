output "lambda_iam_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "lambda_iam_role_name" {
  value = aws_iam_role.lambda_role.name
}

output "glue_iam_role_arn" {
  value = aws_iam_role.glue_role.arn
}

output "glue_iam_role_name" {
  value = aws_iam_role.glue_role.name
}

output "step_function_role_arn" {
  value = aws_iam_role.step_function_role.arn
}

output "step_function_role_name" {
  value = aws_iam_role.step_function_role.name
}