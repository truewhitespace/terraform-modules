output "method_id" {
  description = "The method ID created for this endpoint"
  value       = aws_api_gateway_method.this.id
}

output "integration_id" {
  description = "The integration ID created for this endpoint"
  value       = aws_api_gateway_integration.this.id
}

output "lambda_permission_id" {
  description = "The Lambda permission ID"
  value       = aws_lambda_permission.this.id
}
