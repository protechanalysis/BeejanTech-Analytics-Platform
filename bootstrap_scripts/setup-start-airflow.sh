#!/bin/bash

cd /home/ubuntu/airflow

# Download entrypoint script from S3
aws s3 sync s3://cloud-platform-airflow/bootstrap_scripts/entrypoint.sh /home/ubuntu/airflow/entrypoint.sh

# Download the Docker Compose file from S3
aws s3 sync s3://cloud-platform-airflow/docker-compose.yaml /home/ubuntu/airflow/docker-compose.yaml

# Download the Docker Compose file from S3
aws s3 sync s3://cloud-platform-airflow/Dockerfile /home/ubuntu/airflow/Dockerfile


# Set the Airflow UID
echo -e "AIRFLOW_UID=$(id -u)" > .env

# Build the cutom image
# docker build -t custom-airflow-platform:latest .

# Start Airflow using Docker Compose
# /usr/local/bin/docker-compose up airflow-init
/usr/local/bin/docker-compose build


# Start all services in detached mode
/usr/local/bin/docker-compose up -d

echo "[$(date)] Airflow EC2 setup completed."