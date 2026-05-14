/*
 * Singular data test: order updated_at is not on or after today.
 *
 * Fails when: stg_orders.updated_at >= current_date (evaluated at test runtime).
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
    updated_at >= current_date