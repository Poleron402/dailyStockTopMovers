
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

# Scheduling
resource "aws_cloudwatch_event_rule" "get_daily_stock" {
  name = "get_daily_stock"
  description = "Triggers the lambda function every day besides SUN and MON for the past day to get the stock data. API limitations do not permit same day data retrieval, therefore the date is shifted."
  schedule_expression = "cron(5 0 ? * TUE-SAT *)"
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
          aws_dynamodb_table.stock_data_table.arn
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
  timeout = 5

}



# API GATEWAY

resource "aws_api_gateway_rest_api" "crud_api" {
  name        = "crud-api"
  description = "CRUD API Gateway for getting Daily Top Movers in the stock market"
}

resource "aws_api_gateway_resource" "movers" {
  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  parent_id   = aws_api_gateway_rest_api.crud_api.root_resource_id
  path_part   = "movers"
}

resource "aws_api_gateway_method" "movers_get" {
  rest_api_id   = aws_api_gateway_rest_api.crud_api.id
  resource_id   = aws_api_gateway_resource.movers.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "movers_get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.crud_api.id
  resource_id             = aws_api_gateway_resource.movers.id
  http_method             = aws_api_gateway_method.movers_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_lambda.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # allow any stage, GET /movers
  source_arn = "${aws_api_gateway_rest_api.crud_api.execution_arn}/*/GET/movers"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.movers_get_lambda
  ]

  rest_api_id = aws_api_gateway_rest_api.crud_api.id
}