resource "aws_dynamodb_table" "posts" {
  name           = "${var.project}-${var.env}-posts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "scheduled_time"

  attribute {
    name = "user_id"
    type = "S" # String
  }

  attribute {
    name = "scheduled_time"
    type = "S" # String (ISO 8601 format: "2023-11-20T10:00:00Z")
  }

  # Global Secondary Index (GSI) - Optional: To query posts by status (Pending/Done)
  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name               = "StatusIndex"
    hash_key           = "status"
    range_key          = "scheduled_time"
    projection_type    = "ALL"
  }

  tags = {
    Name = "${var.project}-${var.env}-posts-table"
  }
}
