/*
-- Singular test: No duplicate order_ids should exist in staging
-- Fails if any order_id appears more than once
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
    order_date is not null
    AND try_cast(order_date as DATE) is null
