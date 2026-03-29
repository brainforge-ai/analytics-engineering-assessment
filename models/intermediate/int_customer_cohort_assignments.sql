-- Assign customers to reusable cohort definitions for downstream cohort analysis.
-- This model is structured so additional cohort definitions can be added later
-- and unioned into the final assignment table without reshaping downstream marts.

-- ref tables
with orders as (

    select
        customer_id,
        order_month_start
    from {{ ref('int_orders_enriched') }}
    where is_valid_order

),

-- Cohort 1: assign customers to the month of their first valid order.
first_valid_order_month as (

    select
        customer_id,
        min(order_month_start) as cohort_month_start
    from orders
    group by 1

),

cohort_assignments as (

    select
        customer_id,
        'first_valid_order_month' as cohort_type,
        cohort_month_start,
        -- Add a business-readable cohort label.
        cast(strftime(cohort_month_start, '%b %Y') as varchar) as cohort_label
    from first_valid_order_month

    -- Cohort 2 placeholder:
    -- union all
    -- select
    --     customer_id,
    --     'signup_month' as cohort_type,
    --     cohort_month_start,
    --     cast(strftime(cohort_month_start, '%b %Y') as varchar) as cohort_label
    -- from signup_month

)

select
    customer_id,
    cohort_type,
    cohort_month_start,
    cohort_label
from cohort_assignments
