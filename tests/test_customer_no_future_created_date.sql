/*
-- Singular test: Customer records should have create dates in the past.
-- Fails if any customer record has created_at in the future relative to 'current_date' at runtime
*/

SELECT 
    customer_id
    ,email
    ,country
    ,created_at 
FROM
    {{ ref('stg_customers') }}
WHERE 
    created_at >= current_date
