/*
-- Singular test: Customer records should have a valid created_at date
-- Fails if any created_at value returns an invalid date. ex. Feb. 30
*/

SELECT 
    customer_id
    ,email
    ,country
    ,created_at 
FROM
    {{ ref('stg_customers') }}
WHERE 
    created_at is not null
    AND try_cast(created_at as DATE) is null
