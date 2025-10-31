import logging
from data_validation.validate_book import validate_books_df
from data_validation.validate_transaction import validate_transaction_df
from etl.file_from_s3 import read_book_from_s3, read_trans_from_s3

def book_data_validation(execution_date: str) -> None:
    """
    Validates the books data stored in S3 for the given Airflow execution date (YYYY-MM-DD).
    Raises an error if validation fails.
    """
    try:
        df = read_book_from_s3(execution_date)
        if df.empty:
            msg = "Books data read from S3 is empty. Validation failed."
            logging.error(msg)
            raise ValueError(msg)
        validate_books_df(df)
        logging.info("Books data validation passed.")
    except Exception as e:
        logging.error(f"Books data validation failed: {e}", exc_info=True)
        raise


def transaction_data_validation(execution_date: str) -> None:
    """
    Validates the transaction data stored in S3 for the given Airflow execution date (YYYY-MM-DD).
    Raises an error if validation fails.
    """
    try:
        df = read_trans_from_s3(execution_date)
        if df.empty:
            msg = "Transaction data read from S3 is empty. Validation failed."
            logging.error(msg)
            raise ValueError(msg)
        validate_transaction_df(df)
        logging.info("Transaction data validation passed.")
    except Exception as e:
        logging.error(f"Transaction data validation failed: {e}", exc_info=True)
        raise