/*
 * Singular data test: orders reference valid customers.
 *
 * Fails when: a stg_orders.customer_id has no matching stg_customers.customer_id.
 */

SELECT
    order_id
    ,customer_id
    ,order_date
    ,status
    ,total_amount
    ,currency
    ,updated_at
FROM 
    {{ref('stg_orders')}} ord
WHERE NOT EXISTS (
        SELECT
            1
        FROM
            {{ref('stg_customers')}} cust
        WHERE 
            cust.customer_id = ord.customer_id
    )