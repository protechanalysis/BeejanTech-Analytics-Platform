#!/bin/bash
LOG_FILE="/var/log/airflow-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

sudo apt update -y
sudo apt install -y awscli

echo "[$(date)] Starting Airflow EC2 setup..."

# Download setup script from S3
echo "[$(date)] Downloading setup-install.sh from S3..."
aws s3 cp s3://cloud-platform-airflow/bootstrap_scripts/setup-install.sh /home/ubuntu/bootstrap_scripts/setup-install.sh

echo "[$(date)] Setting execute permissions for setup-install.sh..."
chmod +x /home/ubuntu/bootstrap_scripts/setup-install.sh

echo "[$(date)] Running setup-install.sh..."
/home/ubuntu/bootstrap_scripts/setup-install.sh

# Download and execute the start script
echo "[$(date)] Downloading setup-start-airflow.sh from S3..."
aws s3 cp s3://cloud-platform-airflow/bootstrap_scripts/setup-start-airflow.sh /home/ubuntu/bootstrap_scripts/setup-start-airflow.sh

echo "[$(date)] Setting execute permissions for setup-start-airflow.sh..."
chmod +x /home/ubuntu/bootstrap_scripts/setup-start-airflow.sh

echo "[$(date)] Running setup-start-airflow.sh..."
/home/ubuntu/bootstrap_scripts/setup-start-airflow.sh

echo "[$(date)] Airflow EC2 setup completed."

INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
S3_LOG_PATH="s3://cloud-platform-airflow/logs/bootstrap/${INSTANCE_ID}/${TIMESTAMP}-airflow-setup.log"

echo "[$(date)] Uploading log to S3: ${S3_LOG_PATH}"
aws s3 cp "$LOG_FILE" "$S3_LOG_PATH"

echo "[$(date)] Log uploaded successfully."
