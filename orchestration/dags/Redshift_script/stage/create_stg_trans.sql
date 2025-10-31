CREATE TABLE IF NOT EXISTS staging.transactions_stage (
    transaction_id VARCHAR(50) PRIMARY KEY,
    book_id VARCHAR(50),
    quantity BIGINT,
    total_price DECIMAl(10, 2),
    customer_name VARCHAR(200),
    transaction_date TIMESTAMP
);
