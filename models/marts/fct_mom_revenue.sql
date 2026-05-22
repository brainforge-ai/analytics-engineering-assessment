-- models/marts/fct_mom_revenue.sql

{{
    config(materialized='view')
}}

{#
  Month-over-month revenue growth, implemented as a VIEW wrapping
  fct_monthly_revenue. A view always queries the full current state of the
  fact table, which guarantees LAG() sees the complete time series. Computing
  LAG inside the incremental model itself would produce incorrect percentages
  when only a subset of months is re-materialized in a given run.

  mom_growth_pct is a decimal ratio (e.g. 0.15 = +15% growth). NULL for the
  first month per country (no prior period). YYYY-MM alphabetical order equals
  chronological order, so ORDER BY order_year_month is correct without date casting.
#}

with

base as (

    select
        country,
        order_year_month,
        total_revenue,
        order_count,
        avg_order_value

    from {{ ref('fct_monthly_revenue') }}

),

with_prior as (

    select
        country,
        order_year_month,
        total_revenue,
        order_count,
        avg_order_value,

        lag(total_revenue) over (
            partition by country
            order by order_year_month
        )                                               as prior_month_revenue

    from base

),

final as (

    select
        country,
        order_year_month,
        total_revenue,
        order_count,
        avg_order_value,
        prior_month_revenue,

        case
            when prior_month_revenue is null then null
            when prior_month_revenue = 0    then null
            else round(
                (total_revenue - prior_month_revenue) / prior_month_revenue,
                4
            )
        end                                             as mom_growth_pct

    from with_prior

)

select * from final
