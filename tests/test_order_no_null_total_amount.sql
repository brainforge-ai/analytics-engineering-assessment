/*
-- Singular test: No null total_amount should exist in staging
-- Fails if any order_id includes a null value for total_amount
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