COPY staging.transactions_stage
FROM '{{ var.value.trans_data_path }}/{{ ds }}/'
IAM_ROLE '{{ var.value.redshift_iam_role }}'
FORMAT AS PARQUET;
