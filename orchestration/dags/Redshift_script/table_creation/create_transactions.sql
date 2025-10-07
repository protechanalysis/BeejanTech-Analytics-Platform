CREATE TABLE IF NOT EXISTS transactions (
    transaction_id VARCHAR(50) PRIMARY KEY,
    book_id VARCHAR(50),
    quantity BIGINT,
    total_price DECIMAl(10, 2),
    customer_name VARCHAR(200),
    transaction_date TIMESTAMP,
    
    CONSTRAINT fk_book
        FOREIGN KEY(book_id) REFERENCES books(book_id)
);
