from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

def print_hello():
    for i in range(1, 51):  # Loop from 1 to 50
        print(f"Hello {i}")

# Define DAG
with DAG(
    dag_id="hello_50_times",
    start_date=datetime(2025, 8, 28),
    schedule=None,   # Run only when triggered
    catchup=False,
    tags=["example"],
) as dag:

    task1 = PythonOperator(
        task_id="print_hello_task",
        python_callable=print_hello,
    )

    task1