CREATE TABLE IF NOT EXISTS staging.books_stage (
    book_id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(500),
    author VARCHAR(200),
    genre VARCHAR(100),
    price DECIMAl(10, 2),
    isbn VARCHAR(20),
    publication_year BIGINT,
    pages BIGINT
);
