import logging
from config.gen_book import generate_books
from config.database_query import insert_books
from config.set_variable import num_books


logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

def book_ingest() -> None:
    """
    Generate and insert books into the database.
    Uses the number of books specified in Airflow Variables.
    """
    try:
        n = int(num_books)
        logging.info(f"Generating and inserting {n} books into the database.")
        books = generate_books(n)
        insert_books(books)
        logging.info(f"{n} books ingestion completed successfully.")
    except Exception as e:
        logging.error(f"Error during book ingestion: {e}", exc_info=True)
        raise
