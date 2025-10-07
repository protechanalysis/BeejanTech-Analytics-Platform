import uuid
import random
from datetime import datetime
import logging
import pandas as pd
from config.database_query import query_book_id
from config.set_variable import num_trans

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

def generate_transaction(execution_datetime: datetime) -> pd.DataFrame:
    """
    Generate fake book purchase transactions for ALL books retrieved.
    Args:
        num_trans (int): Number of transactions to generate per book.
    Returns:
        pd.DataFrame: DataFrame of generated transactions.
    Raises:
        ValueError: If no books are found or invalid inputs.
    """
    try:
        logging.info(f"Starting transaction generation for {num_trans} transactions per book.")
        if num_trans <= 0:
            raise ValueError("num_trans must be greater than zero.")

        query_db_books = query_book_id()
        logging.info(f"Retrieved {len(query_db_books)} books from the database.")
        # Handle both DataFrame and list returns
        if isinstance(query_db_books, pd.DataFrame):
            # It's a DataFrame
            if query_db_books.empty:
                msg = "Books table query returned no records. Aborting transaction generation."
                logging.error(msg)
                raise ValueError(msg)
            books_data = query_db_books
            
        elif isinstance(query_db_books, list):
            # It's a list - convert to DataFrame
            if not query_db_books:  # Empty list
                msg = "Books table query returned no records. Aborting transaction generation."
                logging.error(msg)
                raise ValueError(msg)
            
            # Convert list to DataFrame
            # Assuming list contains tuples like [(book_id, price), ...]
            books_data = pd.DataFrame(query_db_books, columns=['book_id', 'price'])
            logging.info(f"Converted list of {len(query_db_books)} books to DataFrame")
            
        else:
            raise TypeError(f"Expected DataFrame or list, got {type(query_db_books)}")

        trans_log = []
        logging.info("Generating transactions...")
        for _, row in books_data.iterrows():
            book_id, price = row["book_id"], row["price"]
            logging.debug(f"Generating transactions for book_id: {book_id}, price: {price}")

            for _ in range(num_trans):
                quantity = random.randint(1, 100)
                tx = {
                    "transaction_id": str(uuid.uuid4()),
                    "book_id": str(book_id),  # Ensure it's a string
                    "quantity": quantity,
                    "total_price": round(float(price) * quantity, 2),
                    "customer_name": f"Customer_{random.randint(1, 100)}",
                    "transaction_date": execution_datetime
                }
                trans_log.append(tx)
                logging.info(f"Generated transaction appended")

        trans_df = pd.DataFrame(trans_log)
        logging.info(f"Generated {len(trans_df)} transactions for {len(books_data)} books.")
        return trans_df

    except Exception as e:
        logging.error(f"Error in generate_transaction: {e}", exc_info=True)
        raise