-- Singular test: total revenue in fct_monthly_revenue must reconcile with
-- the sum of eligible order amounts in int_orders.
--
-- Any row returned means there is a discrepancy between the mart aggregate
-- and its upstream source — indicating a bug in eligibility filtering,
-- incremental logic, or aggregation.

with mart_total as (

    select round(sum(total_revenue), 2) as total
    from {{ ref('fct_monthly_revenue') }}

),

source_total as (

    select round(sum(total_amount), 2) as total
    from {{ ref('int_orders') }}
    where is_revenue_eligible = true
      and country is not null

),

comparison as (

    select
        mart_total.total   as mart_revenue,
        source_total.total as source_revenue,
        mart_total.total - source_total.total as discrepancy
    from mart_total
    cross join source_total

)

select *
from comparison
where abs(discrepancy) > 0.01
