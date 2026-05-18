{{ config(materialized='view') }}

-- Clean, deduplicated orders that passed every staging-layer data-quality rule.
-- Rejected rows are not dropped but live in stg_orders__quarantine with a
-- reason code so that downstream DQ monitoring can count them.

select
    order_id,
    customer_id,
    order_date,
    status,
    total_amount,
    currency,
    updated_at,
    strftime(order_date, '%Y-%m') as year_month
from {{ ref('stg_orders__labeled') }}
where dq_reason is null
