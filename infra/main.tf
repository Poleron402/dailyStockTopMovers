
provider "aws" {
  region = "us-west-1"
}

# dynamo db setup
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

# Lambda for fetching api data and storing in dynamo
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iamrole" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "dynamoDBLambdaPolicy" {
  name = "DynamoDBLambdaPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = [
          aws_dynamodb_table.stock_data_table.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda-policy-attachment" {
  role       = aws_iam_role.iamrole.name
  policy_arn = aws_iam_policy.dynamoDBLambdaPolicy.arn
}


data "archive_file" "lambda_zip" {  
  type = "zip"  
  source_dir  = "../be-save/lambda"
  output_path = "lambda.zip"
}


resource "aws_lambda_function" "massive_api_lambda" {
  function_name    = "getStockData"
  runtime          = "python3.12"
  role             = aws_iam_role.iamrole.arn
  handler          = "script.lambda_handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout = 80
  environment {
    variables = {
      API_KEY = var.massive_api_key
    }
  }
}

# 