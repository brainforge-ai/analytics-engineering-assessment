/*
 * Singular data test: order_date is not on or after today.
 *
 * Fails when: stg_orders.order_date >= current_date (evaluated at test runtime).
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
    order_date >= current_date
