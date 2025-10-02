from datetime import datetime
import logging
import pandas as pd
import awswrangler as wr
from awswrangler import _config
from config.database_query import query_books_df
from config.transactions import generate_transaction
from config.set_variable import book_path, transaction_path, book_type, trans_type

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')


def upload_book_to_s3(execution_date: str) -> pd.DataFrame:
    """
    Query the books table and upload result to S3 as a Parquet file.
    Raises an error if the table is empty.
    
    Returns:
        str: The S3 path where the file was saved (XCom friendly).
    """
    
    try:
        original_engine = wr.engine.get()
        wr.engine.set("python")
        df = query_books_df()
        file_path = f"{book_path}/{execution_date}"
        if df.empty:
            msg = "Books table query returned no records. Aborting upload."
            logging.error(msg)
            raise ValueError(msg)
        df["publication_year"] = pd.to_numeric(df["publication_year"], errors="coerce").fillna(0).astype("int64")
        df["pages"] = pd.to_numeric(df["pages"], errors="coerce").fillna(0).astype("int64")
        wr.s3.to_parquet(
            df=df, 
            path=file_path, 
            dataset=True, 
            mode="overwrite",
            dtype=book_type
            )
        logging.info(f"Saved books data to {file_path}")
    except Exception as e:
        logging.error(f"Failed to upload books data to S3: {e}", exc_info=True)
        raise


def upload_transaction_to_s3(execution_date: str) -> pd.DataFrame:
    """
    Save the DataFrame to S3 as a Parquet file using awswrangler.
    Raises an error if the upload fails.
    """
    try:
        original_engine = wr.engine.get()
        wr.engine.set("python")
        execution_datetime = datetime.strptime(execution_date, "%Y-%m-%d")
        df = generate_transaction(execution_datetime)
        df["quantity"] = pd.to_numeric(df["quantity"], errors="coerce").fillna(0).astype("int64")
        file_path = f"{transaction_path}/{execution_date}"
        logging.info(f"Uploading DataFrame to {file_path} using awswrangler")
        wr.s3.to_parquet(
            df=df,
            path=file_path,
            dataset=True,
            mode="overwrite",
            dtype=trans_type
        )
        logging.info(f"Saved DataFrame to {file_path}")
    except Exception as e:
        logging.error(f"Failed to save DataFrame to S3: {e}")
        raise