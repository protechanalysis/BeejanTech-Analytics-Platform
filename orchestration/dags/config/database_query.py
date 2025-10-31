import logging
import pandas as pd
from typing import List, Dict, Any, Union
from airflow.providers.postgres.hooks.postgres import PostgresHook
from config.set_variable import postgres_conn_id

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

def create_books_table():
    """
    Create the books table and indexes if they do not exist using Airflow's PostgresHook.
    Args:
        postgres_conn_id (str): Airflow Postgres connection ID.
    Raises:
        Exception: If table or index creation fails.
    """
    table_sql = """
    CREATE TABLE IF NOT EXISTS books (
        book_id VARCHAR(50) PRIMARY KEY,
        title VARCHAR(500) NOT NULL,
        author VARCHAR(200) NOT NULL,
        genre VARCHAR(100) NOT NULL,
        price NUMERIC(10, 2),
        isbn VARCHAR(20) UNIQUE,
        publication_year INTEGER,
        pages INTEGER
    );
    """
    indexes = [
        "CREATE INDEX IF NOT EXISTS idx_books_author ON books(author);"
    ]
    try:
        hook = PostgresHook(postgres_conn_id=postgres_conn_id)
        with hook.get_conn() as conn:
            with conn.cursor() as cursor:
                cursor.execute(table_sql)
                for idx in indexes:
                    cursor.execute(idx)
                conn.commit()
                logging.info("Books table and indexes created successfully!")
    except Exception as e:
        logging.error(f"Error creating books table or indexes: {e}", exc_info=True)
        raise

def insert_books(books: Union[List[Dict[str, Any]], Dict[str, Any], tuple]) -> None:
    """
    Insert a list of books into the database using Airflow's PostgresHook.
    Args:
        books: List of book dictionaries, a single book dict, or a tuple (valid_books, invalid_books).
        postgres_conn_id (str): Airflow Postgres connection ID.
    Raises:
        Exception: If insertion fails.
    """
    insert_sql = """
    INSERT INTO books (book_id, title, author, genre, price, isbn, publication_year, pages)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    ON CONFLICT (isbn) DO NOTHING;
    """
    # Normalize input
    if isinstance(books, dict):
        books = [books]
    elif isinstance(books, tuple) and len(books) == 2:
        books = books[0]
    if not isinstance(books, list) or not all(isinstance(b, dict) for b in books):
        raise ValueError("books must be a list of dicts, a dict, or a (valid_books, invalid_books) tuple")
    try:
        hook = PostgresHook(postgres_conn_id=postgres_conn_id)
        with hook.get_conn() as conn:
            try:
                with conn.cursor() as cursor:
                    for book in books:
                        # Validate required fields
                        required_fields = ["book_id", "title", "author", "genre", "price", "isbn", "publication_year", "pages"]
                        for field in required_fields:
                            if field not in book:
                                raise ValueError(f"Missing required field '{field}' in book: {book}")
                        cursor.execute(insert_sql, (
                            book["book_id"], book["title"], book["author"],
                            book["genre"], book["price"], book["isbn"],
                            book["publication_year"], book["pages"]
                        ))
                    conn.commit()
                    logging.info(f"Inserted {len(books)} books into the database.")
            except Exception as e:
                conn.rollback()
                logging.error(f"Error inserting books: {e}", exc_info=True)
                raise
    except Exception as e:
        logging.error(f"Database connection or insertion error: {e}", exc_info=True)
        raise


def query_books_df() -> pd.DataFrame:
    """
    Query the books table and return the result as a pandas DataFrame.
    Args:
        postgres_conn_id (str): Airflow Postgres connection ID.
    Returns:
        pd.DataFrame: DataFrame of books table.
    """
    try:
        hook = PostgresHook(postgres_conn_id=postgres_conn_id)
        df = hook.get_pandas_df("SELECT * FROM books;")
        logging.info(f"Fetched {len(df)} records from books table.")
        return df
    except Exception as e:
        logging.error(f"Error querying books table: {e}", exc_info=True)
        raise


def query_book_id():
    """
    Query the database for book IDs and prices using Airflow's PostgresHook.
    Returns:
        List of tuples (book_id, price).
    """
    try:
        hook = PostgresHook(postgres_conn_id=postgres_conn_id)
        records = hook.get_records("SELECT book_id, price FROM books;")
        return records
    except Exception as e:
        logging.error(f"Error querying database: {e}", exc_info=True)
        return []
