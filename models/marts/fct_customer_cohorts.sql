{{ config(materialized='table') }}

-- Customer cohort retention.  One row per (cohort_month, months_since_first_order).
--
-- Why cohort instead of MoM or 30-day rolling?
--   The seed contains ~1k orders spanning roughly three calendar months.
--   * Month-over-month gives at most two growth data points -- thin signal.
--   * 30-day rolling on country x day is jittery for small countries with
--     gaps in daily activity.
--   * Cohort flattens the volume problem: every customer contributes to
--     exactly one cohort, and offsets compress the time dimension into a
--     small, readable matrix.  It is the metric this dataset can actually
--     support.
--
-- Output grain: cohort_month x months_since_first_order
-- Output columns: cohort_size, active_customers, retention_rate,
--                 cohort_revenue, avg_order_value

with revenue_orders as (

    select *
    from {{ ref('int_orders_enriched') }}
    where is_revenue_recognizable = true

),

first_orders as (

    select
        customer_id,
        min(order_date)                            as first_order_date,
        strftime(min(order_date), '%Y-%m')         as cohort_month
    from revenue_orders
    group by 1

),

cohort_size as (

    -- Cohort size = customers whose first revenue-recognised order falls in
    -- that month.  Computed once so retention_rate has a stable denominator.
    select
        cohort_month,
        count(distinct customer_id) as cohort_size
    from first_orders
    group by 1

),

activity as (

    select
        f.cohort_month,
        date_diff('month', f.first_order_date, o.order_date) as months_since_first_order,
        o.customer_id,
        o.total_amount
    from revenue_orders o
    inner join first_orders f
      on o.customer_id = f.customer_id

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
    a.cohort_month,
    a.months_since_first_order,
    cs.cohort_size,
    a.active_customers,
    cast(a.active_customers as double) / nullif(cs.cohort_size, 0) as retention_rate,
    a.cohort_revenue,
    a.avg_order_value
from aggregated a
left join cohort_size cs
  on a.cohort_month = cs.cohort_month
order by a.cohort_month, a.months_since_first_order
