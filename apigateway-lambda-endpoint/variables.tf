variable "rest_api_id" {
  type        = string
  description = "The ID of the API Gateway REST API"
}

variable "resource_id" {
  type        = string
  description = "The ID of the API Gateway Resource"
}

variable "resource_path" {
  type        = string
  description = "The path of the API Gateway Resource"
}

variable "rest_api_execution_arn" {
  type        = string
  description = "The execution ARN of the API Gateway REST API"
}

variable "http_method" {
  type        = string
  description = "The HTTP method (e.g., GET, POST, PUT)"
  default     = "POST"
}

variable "lambda_function_name" {
  type        = string
  description = "The name of the Lambda function"
}

variable "lambda_alias_name" {
  type        = string
  description = "The alias name of the Lambda function"
}

variable "lambda_invoke_arn" {
  type        = string
  description = "The ARN to invoke the Lambda function"
}

variable "api_integration_type" {
  type        = string
  description = "The integration type: MOCK, HTTP, HTTP_PROXY, AWS, AWS_PROXY"
  default     = "AWS_PROXY"
}
