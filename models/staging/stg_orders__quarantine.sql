-- Rejected order rows with the reason they failed DQ checks.
-- Use this model to build DQ dashboards: count by dq_reason over time
-- to make data quality regressions visible and measurable.
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
