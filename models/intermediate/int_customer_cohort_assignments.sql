-- Assign customers to reusable cohort definitions for downstream cohort analysis.
-- Starter setup so other cohorts could be added/unioned in in the future. 

-- ref tables
with orders as (

    select
        customer_id,
        order_month_start
    from {{ ref('int_orders_enriched') }}
    where is_valid_order

),

-- Cohort 1: Current cohort definition: the month of each customer's first valid order.
first_valid_order_month as (

    select
        customer_id,
        min(order_month_start) as cohort_month_start
    from orders
    group by 1

)

-- Cohort 2:

-- Publish the current set of cohort assignments.
select
    -- base information
    customer_id,

    -- cohort 1
    'first_valid_order_month' as cohort_type,
    cohort_month_start,
    -- Add a business-readable cohort label.
    cast(strftime(cohort_month_start, '%b %Y') as varchar) as cohort_label

    -- cohort 2

from first_valid_order_month
