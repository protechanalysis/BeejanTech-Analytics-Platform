from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from datetime import datetime, timedelta
from etl.upload_file import upload_book_to_s3, upload_transaction_to_s3
from etl.book_gen import book_ingest
from config.database_query import create_books_table
from etl.validation import book_data_validation, transaction_data_validation

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2025, 9, 21),# start immediately
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

    book_table_creation = PythonOperator(
        task_id='create_books_table',
        python_callable=create_books_table,
    )

    insert_books_task = PythonOperator(
        task_id='insert_books',
        python_callable=book_ingest,
    )

    book_to_s3 = PythonOperator(
        task_id='upload_books_to_s3',
        python_callable=upload_book_to_s3, 
        op_args=['{{ ds }}'],
    )

    trans = PythonOperator(
        task_id='upload_transactions_to_s3',
        python_callable=upload_transaction_to_s3,
        op_args=['{{ ds }}'],
    )

    validate_books = PythonOperator(
        task_id='validate_books_data',
        python_callable=book_data_validation,
        op_args=['{{ ds }}'],
    )

    validate_transactions = PythonOperator(
        task_id='validate_transaction_data',
        python_callable=transaction_data_validation,
        op_args=['{{ ds }}'],
    )


    book_table_dwh= SQLExecuteQueryOperator(
        task_id="create_dwh_book_table",
        conn_id="redshift_default",
        sql="Redshift_script/table_creation/create_book.sql",
    )

    transactions_table_dwh= SQLExecuteQueryOperator(
        task_id="create_dwh_transaction_table",
        conn_id="redshift_default",
        sql="Redshift_script/table_creation/create_transactions.sql",
    )

    schema_stg = SQLExecuteQueryOperator(
        task_id="create_staging_schema",
        conn_id="redshift_default",
        sql="CREATE SCHEMA IF NOT EXISTS staging;",
    )

    stage_book = SQLExecuteQueryOperator(
        task_id="create_stg_book",
        conn_id="redshift_default",
        sql="Redshift_script/stage/create_stg_book.sql",
    )

    stage_trans = SQLExecuteQueryOperator(
        task_id="create_stg_trans",
        conn_id="redshift_default",
        sql="Redshift_script/stage/create_stg_trans.sql",
    )

    trunc_stage_book = SQLExecuteQueryOperator(
        task_id="trunc_stage_book",
        conn_id="redshift_default",
        sql="Truncate staging.books_stage;",
    )

    trunc_stage_trans = SQLExecuteQueryOperator(
        task_id="trunc_stage_trans",
        conn_id="redshift_default",
        sql="Truncate staging.transactions_stage;",
    )

    copy_stage_book = SQLExecuteQueryOperator(
        task_id="copy_to_stg_book",
        conn_id="redshift_default",
        sql="Redshift_script/stage/stg_book.sql",
    )

    copy_stage_trans = SQLExecuteQueryOperator(
        task_id="copy_to_stg_trans",
        conn_id="redshift_default",
        sql="Redshift_script/stage/stg_transaction.sql",
    )

    merge_book = SQLExecuteQueryOperator(
        task_id="merge_book_to_main",
        conn_id="redshift_default",
        sql="Redshift_script/merge/main_book.sql",
    )

    merge_trans = SQLExecuteQueryOperator(
        task_id="merge_trans_to_main",
        conn_id="redshift_default",
        sql="Redshift_script/merge/main_transaction.sql",
    )


    book_table_creation >> insert_books_task >> [book_to_s3, trans]
    # book branch
    book_to_s3 >> validate_books >> schema_stg >> stage_book
    stage_book >> trunc_stage_book >> copy_stage_book >> book_table_dwh >> merge_book
    # Transaction branch
    trans >> validate_transactions >> schema_stg >> stage_trans
    stage_trans >> trunc_stage_trans >> copy_stage_trans >> transactions_table_dwh >> merge_trans
    
