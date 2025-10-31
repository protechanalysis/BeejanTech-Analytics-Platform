#!/bin/bash

# Update and install dependencies
apt update -y
apt install -y docker.io

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Add ubuntu to the Docker group
usermod -a -G docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install and enable AWS SSM Agent
echo "=== Installing Amazon SSM Agent ==="
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service --no-pager

# Create directories for Airflow
mkdir -p /home/ubuntu/airflow/dags /home/ubuntu/airflow/logs /home/ubuntu/airflow/plugins /home/ubuntu/airflow/config

# Sync DAGs from S3 if they exist arn:aws:s3:::cloud-platform-airflow
if aws s3 ls s3://cloud-platform-airflow/dags/ >/dev/null 2>&1; then
    aws s3 sync s3://cloud-platform-airflow/dags/ /home/ubuntu/airflow/dags/
else
    echo "No DAGs found in s3://cloud-platform-airflow/dags/"
fi

# # Set permissions
# chown -R ubuntu:ubuntu /home/ubuntu/airflow