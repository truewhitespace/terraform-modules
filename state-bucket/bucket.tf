
resource "aws_s3_bucket" "state" {
  bucket = var.name
  acl    = "private"

  tags = {
    name        = "State"
    cost_center = "terraform infrastructure"
  }
}

resource "aws_dynamodb_table" "lock_table" {
  name     = var.name
  hash_key = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    name        = "State"
    cost_center = "terraform infrastructure"
  }
}
