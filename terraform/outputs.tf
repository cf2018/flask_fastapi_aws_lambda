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

output "flask_api_endpoint" {
  description = "Invoke URL for the Flask HTTP API"
  value       = aws_apigatewayv2_api.flask_http_api.api_endpoint
}

output "flask_lambda_function_name" {
  value = aws_lambda_function.flask_lambda.function_name
}
