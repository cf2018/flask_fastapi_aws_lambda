variable "project_name" {
  description = "Project name used for tagging and naming resources"
  type        = string
  default     = "fastapi_aws_lambda"
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "fastapi_aws_lambda"
}

variable "flask_lambda_function_name" {
  description = "Name of the Flask Lambda function"
  type        = string
  default     = "flask_aws_lambda"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}
