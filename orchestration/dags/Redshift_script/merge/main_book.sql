MERGE INTO public.books
USING staging.books_stage AS s
ON public.books.book_id = s.book_id
WHEN MATCHED THEN
    UPDATE SET
        title = s.title,
        author = s.author,
        genre = s.genre,
        price = s.price,
        isbn = s.isbn,
        publication_year = s.publication_year,
        pages = s.pages
WHEN NOT MATCHED THEN
    INSERT (book_id, title, author, genre, price, isbn, publication_year, pages)
    VALUES (s.book_id, s.title, s.author, s.genre, s.price, s.isbn, s.publication_year, s.pages);
