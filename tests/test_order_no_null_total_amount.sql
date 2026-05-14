/*
 * Singular data test: every order has a total_amount.
 *
 * Fails when: total_amount is null on stg_orders.
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
    total_amount is null