
provider "aws" {
  region = "us-west-1"
}

resource "aws_dynamodb_table" "stock_data_table" {
  name = "StockData"
  billing_mode = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 5
  hash_key       = "date"

  attribute {
    name="date"
    type="S"
  }
  
}