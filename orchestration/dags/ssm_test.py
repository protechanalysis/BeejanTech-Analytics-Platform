from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

def print_hello():
    for i in range(1, 14):  # Loop from 1 to 14
        print(f"ssm hello {i}")

# Define DAG
with DAG(
    dag_id="hello_times_14",
    start_date=datetime(2025, 10, 8),
    schedule=None,   # Run only when triggered
    catchup=False,
    tags=["example"],
) as dag:

    task1 = PythonOperator(
        task_id="print_hello_task",
        python_callable=print_hello,
    )

    task1