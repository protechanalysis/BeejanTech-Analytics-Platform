import uuid
import random
from faker import Faker
import logging


# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

fake = Faker()

def generate_books(num_books):
    """
    Generate a list of fake books with realistic data.
    
    Args:
        num_books (int): Number of books to generate
        
    Returns:
        list: List of dictionaries containing book data
    """
    try:
        logging.info(f"Generating {num_books} books.")
        genres = [
            "Fiction", "Mystery", "Romance", "Science Fiction", "Fantasy", 
            "Thriller", "Biography", "History", "Self-Help", "Business",
            "Poetry", "Drama", "Horror", "Adventure", "Literary Fiction",
            "Young Adult", "Children's", "Philosophy", "Psychology", "Health"
        ]
        
        books = []
        for _ in range(num_books):
            # Generate more realistic book titles (remove period, title case)
            title = fake.sentence(nb_words=random.randint(2, 5)).rstrip('.')
            title = title.title()
            
            book = {
                "book_id": str(uuid.uuid4()),
                "title": title,
                "author": fake.name(),
                "genre": random.choice(genres),
                "price": round(random.uniform(10.99, 99.99), 2),
                "isbn": fake.isbn13(),
                "publication_year": random.randint(1950, 2024),
                "pages": random.randint(100, 800)
            }
            books.append(book)
        logging.info(f"Generated {len(books)} books successfully.")
        return books
        
    except Exception as e:
        logging.error(f"Error generating books: {e}", exc_info=True)
        raise
