/*
-- Singular test: No order_ids with null order_date should exist in staging
-- Fails if any order_id with null order_date
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