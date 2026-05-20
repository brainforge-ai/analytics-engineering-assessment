-- Clean orders only; rejected rows flow to stg_orders__quarantine.
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
