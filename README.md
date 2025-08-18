# FastAPI on AWS Lambda (Terraform)

A simple, extensible, production-friendly FastAPI scaffold designed for AWS Lambda behind API Gateway, using Terraform for infrastructure-as-code and Mangum as the ASGI adapter.

## Features
- Service/Repository project layout
- AWS Lambda + API Gateway (HTTP API) via Terraform
- Mangum to bridge ASGI to Lambda
- .env config via pydantic-settings + python-dotenv
- Easy to extend (add SQS, DB, multiple Lambdas)

## Project Structure
```
app/
  api/
    routes.py
  services/
    hello_service.py
  repositories/
    stub_repo.py
  dependencies/
  core/
    config.py
  main.py
handler.py
requirements.txt
.env
terraform/
  main.tf
  variables.tf
  outputs.tf
  lambda.tf
```

## Quickstart

### 1) Create and upload the Lambda package
We ship a tiny packager that zips the app and dependencies into `build/fastapi_aws_lambda.zip` for Terraform to upload.

```
make build
```

Or use the Python script:

```
python scripts/package_lambda.py
```

This produces `build/fastapi_aws_lambda.zip` used by Terraform.

### 2) Deploy infrastructure with Terraform
```
cd terraform
terraform init
terraform apply -var "aws_region=${AWS_REGION:-us-east-1}" -var "environment=${STAGE:-dev}" -var "lambda_function_name=${LAMBDA_NAME:-fastapi_aws_lambda}"

fast way:
make build
cd terraform && terraform init && terraform apply
```

Outputs will show the `api_endpoint`. Test it:

```
curl "$API_ENDPOINT/"
```

### 3) Local dev (optional)
```
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Visit http://localhost:8000/ and http://localhost:8000/docs

## Extensibility
- Add new endpoints under `app/api`
- Add services under `app/services` and repositories under `app/repositories`
- Add new Lambda handlers by creating more entrypoints like `handler.py` and updating Terraform
- Introduce SQS, DynamoDB, or other AWS services in Terraform, then wire repos/services

## Environment
`.env` controls runtime defaults; Terraform also passes the key ones into Lambda.

```
APP_ENV=dev
STAGE=dev
AWS_REGION=us-east-1
LAMBDA_NAME=fastapi_aws_lambda
```

## Notes
- Lambda runtime set to Python 3.12 (see `terraform/lambda.tf`). Ensure your local packaging uses the same Python minor version to avoid binary wheel issues.
- Minimal dependencies purposely kept small
- Swap to Poetry easily by adding `pyproject.toml`
