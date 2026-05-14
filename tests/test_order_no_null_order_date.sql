/*
 * Singular data test: every order has an order_date.
 *
 * Fails when: order_date is null on stg_orders.
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
    order_date is null