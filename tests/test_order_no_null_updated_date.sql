/*
 * Singular data test: every order has an updated_at timestamp.
 *
 * Fails when: updated_at is null on stg_orders.
 */

select
    order_id
    ,customer_id
    ,order_date
    ,status
    ,total_amount
    ,currency
    ,updated_at
from {{ ref('stg_orders') }}
WHERE 
    updated_at is null