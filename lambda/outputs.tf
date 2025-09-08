output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "function_arn" {
  value = aws_lambda_function.this.arn
}

output "alias_name" {
  value = aws_lambda_alias.alias.name
}

output "alias_arn" {
  value = aws_lambda_alias.alias.arn
}

output "invoke_arn" {
  value = aws_lambda_alias.alias.invoke_arn
}