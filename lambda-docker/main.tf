resource "aws_iam_role" "this" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "this" {
  count = length(var.policy_statements) > 0 ? 1 : 0
  name  = var.policy_name
  role  = aws_iam_role.this.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = var.policy_statements
  })
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.this.arn
  timeout       = var.timeout
  memory_size   = var.memory_size

  package_type = "Image"
  image_uri    = var.image_uri

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}


resource "aws_lambda_alias" "alias" {
  name             = "${var.function_name}-alias"
  description      = "Alias for ${var.function_name}"
  function_name    = aws_lambda_function.this.arn
  function_version = aws_lambda_function.this.version
}