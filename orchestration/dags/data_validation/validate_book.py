import logging
import uuid
import pandas as pd
import pandera as pa
from pandera import Column, DataFrameSchema, Check
from datetime import datetime
from typing import Tuple

current_year = datetime.now().year

def _is_valid_uuid(x: str) -> bool:
    try:
        uuid.UUID(x)
        return True
    except Exception:
        return False

book_schema = DataFrameSchema(
    {
        "book_id": Column(
            str,
            checks=Check(lambda s: s.apply(_is_valid_uuid), element_wise=False),
        ),
        "title": Column(str, checks=Check.str_length(min_value=1)),
        "author": Column(str, checks=Check.str_length(min_value=1)),
        "genre": Column(str, checks=Check.str_length(min_value=1)),
        "price": Column(float, checks=Check.gt(0), coerce=True),
        "publication_year": Column(int, checks=Check.in_range(1950, current_year)),
        "pages": Column(int, checks=Check.gt(0)),
    },
    coerce=True,
)


def validate_books_df(df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """
    Validate a DataFrame of books against schema.
    Returns (valid_df, invalid_df).
    Raises ValueError if any rows are invalid, after collecting all errors.
    """
    valid_df = pd.DataFrame()
    invalid_df = pd.DataFrame()

    try:
        # Validate entire DataFrame
        valid_df = book_schema.validate(df, lazy=True)

    except pa.errors.SchemaErrors as e:
        logging.error("Validation failed. Collecting invalid records...")

        failed_idx = e.failure_cases["index"].unique().tolist()

        # Extract invalid rows and annotate with error messages
        invalid_df = df.loc[failed_idx].copy()
        invalid_df["error"] = invalid_df.index.map(
            lambda idx: "; ".join(
                e.failure_cases.loc[e.failure_cases["index"] == idx, "failure_case"].astype(str)
            )
        )

        # Try to validate remaining rows
        try:
            valid_df = book_schema.validate(df.drop(index=failed_idx), lazy=True)
        except Exception:
            valid_df = pd.DataFrame()

        logging.info(f"Validation finished → {len(valid_df)} valid, {len(invalid_df)} invalid")

        # Build detailed error message
        error_details = "\n".join(
            f"Row {idx}: {msg}" for idx, msg in invalid_df["error"].items()
        )

        raise ValueError(f"Validation failed for {len(invalid_df)} rows:\n{error_details}")

    logging.info(f"Validation finished → {len(valid_df)} valid, 0 invalid")
    return valid_df, invalid_df
