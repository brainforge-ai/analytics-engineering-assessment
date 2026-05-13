/*
-- Singular test: Customer Records should have a created_at date
-- Fails if any customer record's created_at date is null
*/

SELECT 
    customer_id
    ,email
    ,country
    ,created_at 
FROM
    {{ ref('stg_customers') }}
WHERE 
    created_at is null
