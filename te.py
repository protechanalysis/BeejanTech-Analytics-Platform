from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
from config.transactions import generate_transaction
from config.update import run_task

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2025, 8, 29),# start immediately
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='bookstore_data_pipeline',
    default_args=default_args,
    description='A simple data pipeline for bookstore',
    schedule='@daily',
    catchup=False,
) as dag:

    update_task = PythonOperator(
        task_id='update_books',
        python_callable=run_task,
    )

    transaction_task = PythonOperator(
        task_id='generate_transactions',
        python_callable=generate_transaction,
    )

    update_task >> transaction_task
