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
  name = var.policy_name
  role = aws_iam_role.this.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = var.policy_statements
  })
}

resource "aws_lambda_function" "this" {
  function_name                  = var.function_name
  role                           = aws_iam_role.this.arn
  handler                        = var.handler
  runtime                        = var.runtime
  filename                       = var.filename
  source_code_hash               = filebase64sha256(var.filename)
  timeout                        = var.timeout
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions

  snap_start {
    apply_on = "PublishedVersions"
  }

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