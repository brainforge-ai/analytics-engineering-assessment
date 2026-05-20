-- Joins clean orders to customer attributes and encodes the revenue recognition rule.
-- All downstream marts read from here so the rule lives in exactly one place.
--
-- Revenue recognition: completed, shipped -> recognised; pending/cancelled/refunded -> not.
--
-- LEFT JOIN on customers is intentional: preserves revenue-recognizable orders even if a
-- customer row is unexpectedly missing (deleted CRM record, referential integrity slip).
-- The relationships test on customer_id is the early warning; LEFT JOIN is the safety net.
-- fct_monthly_revenue already filters country IS NOT NULL, so an orphaned order surfaces
-- as a visible NULL rather than disappearing silently from the pipeline.
with orders as (

    select
        order_id,
        customer_id,
        order_date,
        strftime(order_date, '%Y-%m') as year_month,
        status,
        total_amount,
        currency,
        updated_at
    from {{ ref('int_orders__labeled') }}
    where dq_reason is null
      and row_num = 1

),

customers as (

    select
        customer_id,
        country,
        email,
        email_is_shared
    from {{ ref('stg_customers') }}

)

select
    orders.order_id,
    orders.customer_id,
    customers.country,
    customers.email,
    customers.email_is_shared,
    orders.order_date,
    orders.year_month,
    orders.status,
    orders.total_amount,
    orders.currency,
    orders.updated_at,
    (orders.status in ('completed', 'shipped')) as is_revenue_recognizable
from orders
left join customers
    on orders.customer_id = customers.customer_id
