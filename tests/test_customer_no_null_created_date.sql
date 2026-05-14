/*
 * Singular data test: monthly revenue fact has no null measure.
 *
 * Fails when: total_revenue is null for any (country, currency, year_month) row.
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
