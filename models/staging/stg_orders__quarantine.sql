{{ config(materialized='view') }}

-- Rejected source rows with the reason they failed staging-layer DQ checks.
-- This converts "bad data" from silent loss into an observable metric
-- that can be used in a monitoring dashboard or alert to count by reason over time


select
    order_id,
    customer_id,
    order_date_raw,
    order_date,
    status,
    total_amount,
    currency,
    updated_at,
    dq_reason,
    current_timestamp as quarantined_at
from {{ ref('stg_orders__labeled') }}
where dq_reason is not null
