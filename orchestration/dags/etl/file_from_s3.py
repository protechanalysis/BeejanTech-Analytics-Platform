from datetime import datetime
import awswrangler as wr
import pandas as pd
from config.set_variable import book_path, transaction_path
from awswrangler import _config


def read_book_from_s3(execution_date: str) -> pd.DataFrame:
    """
    Reads parquet file for the given Airflow execution date (YYYY-MM-DD).
    """
    original_engine = wr.engine.get()
    wr.engine.set("python")
    file_path = f"{book_path}/{execution_date}"
    df = wr.s3.read_parquet(path=file_path)
    return df


def read_trans_from_s3(execution_date: str) -> pd.DataFrame:
    """
    Reads today's transactions parquet file from S3.
    """
    original_engine = wr.engine.get()
    wr.engine.set("python")
    file_path = f"{transaction_path}/{execution_date}"
    df = wr.s3.read_parquet(path=file_path)
    return df