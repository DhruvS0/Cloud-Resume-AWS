terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"  # Update if needed
}

# DynamoDB Table
resource "aws_dynamodb_table" "visitor_count_ddb" {
  name         = "VisitorsTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "VisitorsTable"
  }
}

# DynamoDB Table Item - Initializing Visitor Count
resource "aws_dynamodb_table_item" "visitor_count_ddb" {
  table_name = aws_dynamodb_table.visitor_count_ddb.name
  hash_key   = aws_dynamodb_table.visitor_count_ddb.hash_key

  item = <<ITEM
{
  "id": {"S": "visitor_count"},
  "visitors": {"N": "0"}
}
ITEM
}

# Create Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "visitor_counter_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

# Attach Policy to Lambda Role for DynamoDB Access
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Archive Lambda Function Code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "visitor_counter_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "VisitorCounterFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.visitor_count_ddb.name
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_dynamodb_policy]
}

# Create API Gateway
resource "aws_apigatewayv2_api" "visitor_counter_api" {
  name          = "visitor_counter_api"
  protocol_type = "HTTP"
}

# Create API Gateway Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.visitor_counter_api.id
  integration_uri    = aws_lambda_function.visitor_counter_lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

# Create API Gateway Route
resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.visitor_counter_api.id
  route_key = "GET /visitorcount"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Deploy API Gateway
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.visitor_counter_api.id
  name        = "default"
  auto_deploy = true
}

# Grant API Gateway Permission to Invoke Lambda
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_counter_api.execution_arn}/*/*"
}

# Output the API Gateway URL
output "api_url" {
  value = "${aws_apigatewayv2_stage.default_stage.invoke_url}/visitorcount"
}
