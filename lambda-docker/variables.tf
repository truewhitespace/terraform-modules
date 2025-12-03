variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "image_uri" {
  description = "Docker image for lambda"
  type        = string
}
variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 60
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
  default     = ""
}

variable "policy_statements" {
  description = "List of IAM policy statements for Lambda"
  type        = list(any)
  default     = []
}