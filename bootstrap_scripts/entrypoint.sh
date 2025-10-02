#!/bin/bash
set -euo pipefail

# Fetch all parameters once
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

RDS_HOST=$(aws ssm get-parameter --name "db_host" --region $REGION --with-decryption --query "Parameter.Value" --output text)
RDS_USER=$(aws ssm get-parameter --name "db_username" --region $REGION --with-decryption --query "Parameter.Value" --output text)
RDS_DB=$(aws ssm get-parameter --name "db_name" --region $REGION --with-decryption --query "Parameter.Value" --output text)
RDS_PASS=$(aws ssm get-parameter --name "db_password" --region $REGION --with-decryption --query "Parameter.Value" --output text)
REDIS_ENDPOINT=$(aws ssm get-parameter --name "redis_host" --region $REGION --with-decryption --query "Parameter.Value" --output text)
ALB_DNS_NAME=$(aws ssm get-parameter --name "alb_dns" --region $REGION --with-decryption --query "Parameter.Value" --output text)
Secret_Key=$(aws ssm get-parameter --name "secret_key" --region $REGION --with-decryption --query "Parameter.Value" --output text)
fernet_key=$(aws ssm get-parameter --name "fernet_key" --region $REGION --with-decryption --query "Parameter.Value" --output text)
remote_logging=$(aws ssm get-parameter --name "log_path" --region $REGION --with-decryption --query "Parameter.Value" --output text)

# Core Airflow Configuration
AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="postgresql+psycopg2://${RDS_USER}:${RDS_PASS}@${RDS_HOST}:5432/${RDS_DB}"
AIRFLOW__CELERY__BROKER_URL="redis://${REDIS_ENDPOINT}:6379/0"
AIRFLOW__CELERY__RESULT_BACKEND="db+postgresql://${RDS_USER}:${RDS_PASS}@${RDS_HOST}:5432/${RDS_DB}"
AIRFLOW__API_AUTH__JWT_SECRET="${Secret_Key}"
AIRFLOW__CORE__FERNET_KEY="${fernet_key}"
AIRFLOW__WEBSERVER__LOG_FETCH_TIMEOUT_SEC=10

# Webserver / API URLs
AIRFLOW__WEBSERVER__BASE_URL="http://${ALB_DNS_NAME}"
AIRFLOW__API__BASE_URL="http://${ALB_DNS_NAME}"

# Celery Worker Configuration (log serving fix)
AIRFLOW__CORE__HOSTNAME_CALLABLE="socket.gethostname"

# Remote Logging Configuration
AIRFLOW__LOGGING__REMOTE_LOGGING=True
AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER="${remote_logging}"
AIRFLOW__LOGGING__REMOTE_LOG_CONN_ID="aws_default"
AIRFLOW__LOGGING__ENCRYPT_S3_LOGS=False

# AWS Region for SDK / S3 Logging
AWS_DEFAULT_REGION="${REGION}"

# Export all variables
export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN
export AIRFLOW__CELERY__BROKER_URL
export AIRFLOW__CELERY__RESULT_BACKEND
export AIRFLOW__API_AUTH__JWT_SECRET
export AIRFLOW__CORE__FERNET_KEY
export AIRFLOW__WEBSERVER__BASE_URL
export AIRFLOW__API__BASE_URL
export AIRFLOW__CORE__HOSTNAME_CALLABLE
export AIRFLOW__LOGGING__REMOTE_LOGGING
export AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER
export AIRFLOW__LOGGING__REMOTE_LOG_CONN_ID
export AIRFLOW__LOGGING__ENCRYPT_S3_LOGS
export AIRFLOW__WEBSERVER__LOG_FETCH_TIMEOUT_SEC
export AWS_DEFAULT_REGION

exec "$@"