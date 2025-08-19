# FastAPI + Flask on AWS Lambda

This repo deploys two Lambda functions behind HTTP API Gateway:

- fastapi_lambda: a FastAPI app (existing) using Mangum.
- flask_lambda: a Flask app using aWSGI that calls the FastAPI endpoint and renders a simple HTML page.

The Flask Lambda is configured with an environment variable `FASTAPI1_ENDPOINT` pointing to the FastAPI API Gateway endpoint so it can call it in the `"/"` route.

## Features
- Service/Repository project layout
Run the FastAPI API locally on http://localhost:8000:
- Mangum to bridge ASGI to Lambda
- .env config via pydantic-settings + python-dotenv
make fastapi-dev


Run the Flask app locally on http://localhost:5000. It will call the FastAPI running at http://localhost:8000 by default via `FASTAPI1_ENDPOINT`:

```bash
make flask-dev
```
## Project Structure
```
app/
Build both Lambda deployment packages (.zip) under `build/`:
    routes.py
  services/
    hello_service.py
  repositories/
    stub_repo.py
This uses `scripts/package_lambda.py` and outputs:

# FastAPI + Flask on AWS Lambda

Two AWS Lambda functions behind API Gateway (HTTP APIs):

- fastapi_lambda: FastAPI (ASGI) adapted with Mangum.
- flask_lambda: Flask (WSGI) wrapped via asgiref.WsgiToAsgi and then adapted with Mangum.

The Flask Lambda calls the FastAPI endpoint on its root route and renders a simple HTML template.

## Architecture

```text
                  +---------------------------+
                  |      Terraform (IaC)      |
                  |  - IAM role/policy        |
                  |  - S3 bucket (artifacts)  |
                  |  - 2x Lambda functions    |
                  |  - 2x API Gateway (HTTP)  |
                  +-----+---------------------+
                        |
   build/fastapi_lambda.zip   build/flask_lambda.zip
                        |                   |
                        v                   v
                +--------------+     +--------------+
                |  Lambda      |     |  Lambda      |
                | fastapi_*    |     |  flask_*     |
                | Mangum+ASGI  |     | Flask->ASGI  |
                +------+-------+     +------+-------+
                       ^                    |
                       |                    | calls (HTTP)
                       |                    v
               +-------+--------+     +-----+--------+
               | API Gateway    |     | API Gateway  |
               | http_api       |     | flask_http   |
               +--------+-------+     +------+-------+
                        ^                    |
                        | api_endpoint       |
                        +--------------------+
                         injected as FASTAPI1_ENDPOINT
                         env var into flask_* Lambda
```

- FASTAPI1_ENDPOINT: set on the Flask Lambda from the FastAPI API endpoint. For local dev the Flask app defaults to `http://localhost:8000` if the env var is not provided.
- Both APIs use HTTP API (v2) with AWS_PROXY integrations.

## Project structure

```
app/                 # FastAPI service (business logic split by api/services/repositories)
  main.py
  api/routes.py
  services/hello_service.py
  repositories/stub_repo.py
  core/config.py

flask_app/           # Flask app that calls FastAPI and renders HTML
  main.py
  templates/index.html

handler.py           # FastAPI Lambda handler (Mangum)
flask_handler.py     # Flask Lambda handler (WsgiToAsgi + Mangum)

scripts/package_lambda.py   # Builds build/fastapi_lambda.zip and build/flask_lambda.zip with deps

terraform/           # Infra: two Lambdas + two HTTP APIs + IAM + S3
  main.tf
  lambda.tf
  variables.tf
  outputs.tf
  versions.tf

requirements.txt
Makefile
README.md
```

## Local development

- Start FastAPI on port 8000:

```bash
make fastapi-dev
```

- Start Flask on port 5000 (it will call FastAPI at http://localhost:8000 by default):

```bash
make flask-dev
```

Visit:
- FastAPI: http://localhost:8000/ and http://localhost:8000/docs
- Flask:   http://localhost:5000/

To override FastAPI endpoint locally:

```bash
export FASTAPI1_ENDPOINT="http://localhost:8001"
make flask-dev
```

## Build Lambda artifacts

Use the packager to build both zips under `build/`:

```bash
make build
# or
python scripts/package_lambda.py
```

Artifacts produced:
- build/fastapi_lambda.zip
- build/flask_lambda.zip

## Deploy with Terraform

Make sure your AWS credentials are configured (e.g., via AWS_PROFILE). Then:

```bash
cd terraform
terraform init
terraform apply \
  -var "aws_region=${AWS_REGION:-us-east-1}" \
  -var "environment=${STAGE:-dev}" \
  -var "lambda_function_name=${LAMBDA_NAME:-fastapi_aws_lambda}" \
  -var "flask_lambda_function_name=${FLASK_LAMBDA_NAME:-flask_aws_lambda}"

# Shortcut
make tf-apply
```

Outputs include both API endpoints. Test them:

```bash
curl "$(terraform output -raw api_endpoint)/"
curl "$(terraform output -raw flask_api_endpoint)"
```

Destroy:

```bash
make tf-destroy
```

## Configuration

Environment variables used at runtime (in Lambda and/or locally):

```env
APP_ENV=dev
STAGE=dev
AWS_REGION=us-east-1
LAMBDA_NAME=fastapi_aws_lambda
FASTAPI1_ENDPOINT=https://<fastapi_api_id>.execute-api.<region>.amazonaws.com  # injected by Terraform for flask_* Lambda
```

Locally, `FASTAPI1_ENDPOINT` defaults to `http://localhost:8000` if not set.

## Troubleshooting

- CloudWatch logs:
  - FastAPI: `/aws/lambda/fastapi_aws_lambda`
  - Flask: `/aws/lambda/flask_aws_lambda`
- If changes to code don’t reflect after apply: this project uses `source_code_hash` on Lambda resources to force updates when zip contents change.
- Match your local Python when building deps for Lambda runtime (Python 3.12). Avoid platform-specific wheels that don’t exist for Lambda.

## Notes

- Both APIs are API Gateway v2 (HTTP API) using AWS_PROXY integrations.
- Flask handler uses WsgiToAsgi (asgiref) + Mangum for compatibility on HTTP API v2.
- Terraform sanitizes the S3 bucket name (replacing underscores with dashes).
