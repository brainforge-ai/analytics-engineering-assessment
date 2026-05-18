-- Customer cohort retention. Grain: one row per (cohort_month, months_since_first_order).
-- Each customer is assigned to the month of their first revenue-recognised order.
-- We track how many return in each subsequent month.
--
-- Cohort was chosen over MoM growth (only 2 data points across ~3 months of data)
-- and 30-day rolling (too jittery for small per-country volumes).
with revenue_orders as (

    select
        order_id,
        customer_id,
        order_date,
        total_amount
    from {{ ref('int_orders_enriched') }}
    where is_revenue_recognizable = true

),

first_orders as (

    select
        customer_id,
        min(order_date)                    as first_order_date,
        strftime(min(order_date), '%Y-%m') as cohort_month
    from revenue_orders
    group by 1

),

cohort_size as (

    -- Computed once so retention_rate has a stable denominator.
    select
        cohort_month,
        count(distinct customer_id) as cohort_size
    from first_orders
    group by 1

),

activity as (

    select
        first_orders.cohort_month,
        date_diff('month', first_orders.first_order_date, revenue_orders.order_date) as months_since_first_order,
        revenue_orders.customer_id,
        revenue_orders.total_amount
    from revenue_orders
    inner join first_orders
        on revenue_orders.customer_id = first_orders.customer_id

),

aggregated as (

    select
        cohort_month,
        months_since_first_order,
        count(distinct customer_id) as active_customers,
        sum(total_amount)           as cohort_revenue,
        avg(total_amount)           as avg_order_value
    from activity
    group by 1, 2

)

select
    aggregated.cohort_month,
    aggregated.months_since_first_order,
    cohort_size.cohort_size,
    aggregated.active_customers,
    cast(aggregated.active_customers as double) / nullif(cohort_size.cohort_size, 0) as retention_rate,
    aggregated.cohort_revenue,
    aggregated.avg_order_value
from aggregated
left join cohort_size
    on aggregated.cohort_month = cohort_size.cohort_month
order by aggregated.cohort_month, aggregated.months_since_first_order
