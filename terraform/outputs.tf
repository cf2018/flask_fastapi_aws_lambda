output "api_endpoint" {
  description = "Invoke URL for the HTTP API"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "lambda_function_name" {
  value = aws_lambda_function.fastapi_lambda.function_name
}

output "lambda_bucket" {
  value = aws_s3_bucket.lambda_bucket.bucket
}
