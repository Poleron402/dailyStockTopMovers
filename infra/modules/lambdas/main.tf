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

# Scheduling
resource "aws_cloudwatch_event_rule" "get_daily_stock" {
  name = "get_daily_stock"
  description = "Triggers the lambda function every day besides SUN and MON for the past day to get the stock data. API limitations do not permit same day data retrieval, therefore the date is shifted."
  schedule_expression = "cron(10 7 ? * MON-FRI *)"
}
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.get_daily_stock.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.massive_api_lambda.arn
}
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.massive_api_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.get_daily_stock.arn
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
          var.stock_table_arn
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
      DB_NAME=var.database_name
    }
  }
}


# Lambda for fetching api data from dynamo and returning it in json form
resource "aws_iam_policy" "dynamoDBLambdaPolicyGet" {
  name = "DynamoDBLambdaPolicyGet"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem"
        ]
        Resource = [
          var.stock_table_arn
        ]
      }
    ]
  })
}

data "archive_file" "lambda_api_zip" {  
  type = "zip"  
  source_dir  = "../be-fetch/lambda"
  output_path = "lambda-one.zip"
}
resource "aws_iam_role_policy_attachment" "lambda-policy-attachment-get" {
  role       = aws_iam_role.iamrole.name
  policy_arn = aws_iam_policy.dynamoDBLambdaPolicyGet.arn
}
resource "aws_lambda_function" "api_lambda" {
  function_name    = "fetchStockData"
  runtime          = "python3.12"
  role             = aws_iam_role.iamrole.arn
  handler          = "script.handler"

  filename         = data.archive_file.lambda_api_zip.output_path
  source_code_hash = data.archive_file.lambda_api_zip.output_base64sha256
  timeout = 10
  environment {
    variables = {
      DB_NAME=var.database_name
    }
  }
}


