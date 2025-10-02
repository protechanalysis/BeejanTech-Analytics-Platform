from airflow.models import Variable

book_path = Variable.get("book_data_path")
transaction_path = Variable.get("trans_data_path")
num_books = 500
num_trans = 10
# book_path = f"{bucket_path}books.parquet"
# transaction_path = f"{bucket_path}transactions.parquet"
postgres_conn_id = "postgres_default"

book_type={
    "book_id": "string",
    "title": "string",
    "author": "string",
    "genre": "string",
    "isbn": "string",
    "publication_year": "bigint",
    "pages": "bigint",
    "price": "decimal(10,2)"
}


trans_type={
    "transaction_id": "string",
    "book_id": "string",
    "quantity": "bigint",
    "total_price": "decimal(10,2)",
    "customer_name": "string",
    "transaction_date": "timestamp"
}
