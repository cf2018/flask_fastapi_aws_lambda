resource "aws_iam_role" "lambda_exec_role" {
  name               = "${var.project_name}-${var.environment}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "${replace(var.project_name, "_", "-")}-${var.environment}-${random_id.suffix.hex}"
  tags   = local.tags
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_object" "lambda_package" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "${var.lambda_function_name}.zip"
  source = "../build/fastapi_lambda.zip"
  etag   = filemd5("../build/fastapi_lambda.zip")
}

resource "aws_lambda_function" "fastapi_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "handler.handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_package.key
  # Ensure updates are deployed when the artifact changes
  source_code_hash = filebase64sha256("../build/fastapi_lambda.zip")

  environment {
    variables = {
      APP_ENV     = var.environment
      STAGE       = var.environment
      LAMBDA_NAME = var.lambda_function_name
    }
  }

  tags = local.tags
}

# API Gateway v2 (HTTP API)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"
  tags          = local.tags
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.fastapi_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
  tags        = local.tags
}

resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fastapi_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# --- Flask Lambda and API ---

resource "aws_s3_object" "flask_lambda_package" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "${var.flask_lambda_function_name}.zip"
  source = "../build/flask_lambda.zip"
  etag   = filemd5("../build/flask_lambda.zip")
}

resource "aws_lambda_function" "flask_lambda" {
  function_name = var.flask_lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "flask_handler.handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.flask_lambda_package.key
  # Ensure updates are deployed when the artifact changes
  source_code_hash = filebase64sha256("../build/flask_lambda.zip")

  environment {
    variables = {
      APP_ENV           = var.environment
      STAGE             = var.environment
      LAMBDA_NAME       = var.flask_lambda_function_name
      FASTAPI1_ENDPOINT = aws_apigatewayv2_api.http_api.api_endpoint
    }
  }

  tags = local.tags
}

resource "aws_apigatewayv2_api" "flask_http_api" {
  name          = "${var.project_name}-${var.environment}-flask-api"
  protocol_type = "HTTP"
  tags          = local.tags
}

resource "aws_apigatewayv2_integration" "flask_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.flask_http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.flask_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "flask_default_route" {
  api_id    = aws_apigatewayv2_api.flask_http_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.flask_lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "flask_default_stage" {
  api_id      = aws_apigatewayv2_api.flask_http_api.id
  name        = "$default"
  auto_deploy = true
  tags        = local.tags
}

resource "aws_lambda_permission" "flask_allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvokeFlask"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.flask_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.flask_http_api.execution_arn}/*/*"
}
