/*
-- Singular test: No order_id with a future date should exist in staging
-- Fails if any order_id holds an updated date in the future relative to runtime.
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