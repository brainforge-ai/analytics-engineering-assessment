-- Customer cohort mart for the first_valid_order_month cohort definition.

{{ config(
    materialized='table'
) }}

-- This mart answers the following questions for the first_valid_order_month cohort:
-- 1. How large was each cohort?
-- 2. How many customers from that cohort were active in later months?
-- 3. What share of the original cohort was active in each observed month?

-- ref tables
with valid_orders as (

    select
        customer_id,
        order_month_start
    from {{ ref('int_orders_enriched') }}
    where is_valid_order

),

customer_cohorts as (

    select
        customer_id,
        cohort_1_month_start,
        cohort_1_label
    from {{ ref('int_customer_cohort_assignments') }}
    where cohort_type = 'first_valid_order_month'

),

-- Count customers in each cohort, dedupe done in staging so we can count(*)
cohort_sizes as (

    select
        cohort_1_month_start,
        cohort_1_label,
        count(*) as cohort_1_customers_in_cohort
    from customer_cohorts
    group by
        cohort_1_month_start,
        cohort_1_label

),

-- Join customer cohort labels onto orders.
customer_order_activity as (

    select
        valid_orders.customer_id,
        customer_cohorts.cohort_1_month_start,
        customer_cohorts.cohort_1_label,
        valid_orders.order_month_start as observed_month_start,
        cast(strftime(valid_orders.order_month_start, '%b %Y') as varchar) as observed_month,
        -- Month 0 = first order month, month 1 = next month, etc.
        date_diff('month', customer_cohorts.cohort_1_month_start, valid_orders.order_month_start) as cohort_1_months_since_first_order
    from valid_orders
    inner join customer_cohorts
        on valid_orders.customer_id = customer_cohorts.customer_id

),

-- Count the number customers with at least one valid order in each cohort.
cohort_metrics as (

    select
        cohort_1_month_start,
        cohort_1_label,
        observed_month_start,
        observed_month,
        cohort_1_months_since_first_order,
        count(distinct customer_id) as cohort_1_active_customers
    from customer_order_activity
    group by
        cohort_1_month_start,
        cohort_1_label,
        observed_month_start,
        observed_month,
        cohort_1_months_since_first_order

)

-- Publish the final cohort retention output.
select
    cohort_metrics.cohort_1_label as cohort_start_month,
    cohort_metrics.observed_month,
    cohort_metrics.cohort_1_months_since_first_order as months_since_first_order,
    cohort_sizes.cohort_1_customers_in_cohort as customers_in_cohort,
    cohort_metrics.cohort_1_active_customers as active_customers,
    cast(
        round(
            -- Observed-month retention rate = active customers / original cohort size.
            (cohort_metrics.cohort_1_active_customers * 1.0)
            / nullif(cohort_sizes.cohort_1_customers_in_cohort, 0),
            2
        ) as decimal(10, 2)
    ) as observed_month_retention_rate
from cohort_metrics
inner join cohort_sizes
    on cohort_metrics.cohort_1_month_start = cohort_sizes.cohort_1_month_start
order by cohort_metrics.cohort_1_month_start, cohort_metrics.observed_month_start
