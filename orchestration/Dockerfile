# Use the official Airflow 3.0.4 image
FROM apache/airflow:3.0.4

# Switch to airflow user (uid=50000)
USER airflow

# Copy requirements.txt
COPY requirements.txt /requirements.txt

# Install dependencies as airflow user
RUN pip install --no-cache-dir -r /requirements.txt

# To pull secrets from AWS SSM Parameter Store
USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
USER airflow
ENTRYPOINT ["/entrypoint.sh"]
CMD ["airflow", "webserver"]
