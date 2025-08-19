SHELL := /bin/bash

.PHONY: help install dev run build tf-init tf-apply tf-destroy clean flask-dev fastapi-dev

help:
	@echo "Targets: install, fastapi-dev, flask-dev, run, build, tf-init, tf-apply, tf-destroy, clean"

install:
	python -m pip install -r requirements.txt

fastapi-dev: install
	uvicorn app.main:app --reload --port 8000

flask-dev: install
	FASTAPI1_ENDPOINT=http://localhost:8000 python -m flask --app flask_app/main.py run --debug --port 5000

run:
	uvicorn app.main:app --port 8000

build:
	python scripts/package_lambda.py

tf-init:
	cd terraform && terraform init

tf-apply:
	cd terraform && terraform apply -var "aws_region=$${AWS_REGION:-us-east-1}" -var "environment=$${STAGE:-dev}" -var "lambda_function_name=$${LAMBDA_NAME:-fastapi_aws_lambda}" -var "flask_lambda_function_name=$${FLASK_LAMBDA_NAME:-flask_aws_lambda}"

tf-destroy:
	cd terraform && terraform destroy -var "aws_region=$${AWS_REGION:-us-east-1}" -var "environment=$${STAGE:-dev}" -var "lambda_function_name=$${LAMBDA_NAME:-fastapi_aws_lambda}" -var "flask_lambda_function_name=$${FLASK_LAMBDA_NAME:-flask_aws_lambda}"

clean:
	rm -rf build .terraform terraform/.terraform *.tfstate* terraform/*.tfstate*
