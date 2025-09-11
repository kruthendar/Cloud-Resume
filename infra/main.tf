terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 5.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.4" }
  }
}

provider "aws" {
  region = var.region
}

# 5.1 DynamoDB table (serverless billing; 1 primary key "pk")
resource "aws_dynamodb_table" "counter" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.partition_key

  attribute {
    name = var.partition_key
    type = "S"
  }
}

# 5.2 Seed a starting row so the first call returns 1 (optional but helpful)
resource "aws_dynamodb_table_item" "seed" {
  table_name = aws_dynamodb_table.counter.name
  hash_key   = var.partition_key

  item = jsonencode({
    (var.partition_key) = { S = var.partition_value }
    visit_count         = { N = "0" }
  })
}

# 5.3 Package Lambda code into a zip (no manual zipping)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# 5.4 IAM role so Lambda can run
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# 5.5 Least-privilege policy: allow UpdateItem on our table + logs
data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.counter.arn]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "${var.project}-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# 5.6 Lambda function (Python 3.11)
resource "aws_lambda_function" "counter" {
  function_name = "${var.project}-counter"
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "python3.11"
  handler       = "counter.handler"
  filename      = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME      = aws_dynamodb_table.counter.name
      PARTITION_KEY   = var.partition_key
      PARTITION_VALUE = var.partition_value
    }
  }
}

# 5.7 API Gateway HTTP API (lightweight, cheap)
resource "aws_apigatewayv2_api" "httpapi" {
  name          = "${var.project}-api"
  protocol_type = "HTTP"
}

# 5.8 Connect API → Lambda (AWS_PROXY = payload v2 passthrough)
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.httpapi.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.counter.arn
  payload_format_version = "2.0"
}

# 5.9 Route GET /count to the Lambda integration
resource "aws_apigatewayv2_route" "get_count" {
  api_id    = aws_apigatewayv2_api.httpapi.id
  route_key = "GET /count"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 5.10 Default stage with auto-deploy (no manual publish step)
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.httpapi.id
  name        = "$default"
  auto_deploy = true
}

# 5.11 Allow API Gateway to invoke our Lambda
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowInvokeFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.httpapi.execution_arn}/*/*"
}
