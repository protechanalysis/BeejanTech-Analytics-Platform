import uuid
import random
from datetime import datetime
import logging
import pandas as pd
import pandera.pandas as pa
from pandera.pandas import Column, DataFrameSchema, Check

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

schema = DataFrameSchema({
    "transaction_id": Column(str),
    "book_id": Column(str),
    "quantity": Column(int, checks=Check.ge(1)),
    "total_price": Column(float, checks=Check.gt(0), coerce=True),
    "customer_name": Column(str),
    "transaction_date": Column(pa.DateTime, coerce=True),
})

def validate_transaction_df(df: pd.DataFrame) -> bool:
    """
    Validate a DataFrame of transactions against schema.
    Raises ValueError if any rows are invalid, after collecting all errors.
    """
    logging.info("Starting transaction DataFrame validation")
    try:
        schema.validate(df, lazy=True)  # collect all errors, not just first
        logging.info(f"Validation passed: {len(df)} records, all checks ok.")
        return True
    except pa.errors.SchemaErrors as e:
        logging.error("Validation failed. Details below:")
        logging.error(e.failure_cases)  # DataFrame of rows/columns that failed
        raise ValueError("Transaction DataFrame validation failed") from e