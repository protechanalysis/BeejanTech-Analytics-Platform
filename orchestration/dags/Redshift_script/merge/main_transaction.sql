MERGE INTO public.transactions 
USING staging.transactions_stage as st
ON public.transactions.transaction_id = st.transaction_id
WHEN MATCHED THEN
    UPDATE SET
        quantity = st.quantity,
        total_price = st.total_price,
        customer_name = st.customer_name,
        transaction_date = st.transaction_date
WHEN NOT MATCHED THEN
    INSERT (transaction_id, book_id, quantity, total_price, customer_name, transaction_date)
    VALUES (st.transaction_id, st.book_id, st.quantity, st.total_price, st.customer_name, st.transaction_date);
