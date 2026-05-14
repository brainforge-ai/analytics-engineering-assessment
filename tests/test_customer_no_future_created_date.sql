/*
 * Singular data test: customer created_at is not on or after today.
 *
 * Fails when: stg_customers.created_at >= current_date (evaluated at test runtime).
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
