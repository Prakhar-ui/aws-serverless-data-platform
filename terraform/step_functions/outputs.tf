output "step_function_name" {
  value = aws_sfn_state_machine.yt_pipeline_state_machine.name
}

output "step_function_arn" {
  value = aws_sfn_state_machine.yt_pipeline_state_machine.arn
}

output "step_function_status" {
  value = aws_sfn_state_machine.yt_pipeline_state_machine.status
}