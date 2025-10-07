CREATE TABLE IF NOT EXISTS books (
    book_id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    author VARCHAR(200) NOT NULL,
    genre VARCHAR(100) NOT NULL,
    price DECIMAl(10, 2),
    isbn VARCHAR(20) UNIQUE,
    publication_year BIGINT,
    pages BIGINT
);
