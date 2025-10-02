COPY staging.books_stage
FROM '{{ var.value.book_data_path }}/{{ ds }}/'
IAM_ROLE '{{ var.value.redshift_iam_role }}'
FORMAT AS PARQUET;

