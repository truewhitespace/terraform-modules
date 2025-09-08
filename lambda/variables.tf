variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda handler (e.g., com.example.Handler::handleRequest)"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g., java21, nodejs18.x)"
  type        = string
}

variable "filename" {
  description = "Path to deployment package zip file"
  type        = string
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 120
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}

variable "environment_variables" {
  description = "Map of environment variables for Lambda"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "role_name" {
  description = "IAM role name for Lambda"
  type        = string
}

variable "policy_name" {
  description = "IAM policy name for Lambda"
  type        = string
  default = ""
}

variable "policy_statements" {
  description = "List of IAM policy statements for Lambda"
  type        = list(any)
  default = []
}

variable "reserved_concurrent_executions" {
  type        = number
  description = "Max number of concurrent executions for this Lambda. Use -1 for unlimited."
  default     = 5
}
