/*
  fct_revenue_mom_growth — Month-over-month revenue growth per country.
*/

{{
    config(
        materialized='view'
    )
}}

with monthly as (
    select * from {{ ref('fct_monthly_revenue') }}
),

with_lag as (
    select
        country,
        year_month,
        total_revenue,
        order_count,
        avg_order_value,

        lag(total_revenue) over (
            partition by country
            order by year_month
        )                                                   as prior_month_revenue,

        round(
            100.0
            * (total_revenue
               - lag(total_revenue) over (
                   partition by country
                   order by year_month
                 )
              )
            / nullif(
                lag(total_revenue) over (
                    partition by country
                    order by year_month
                ),
                0
              ),
            2
        )                                                   as mom_revenue_growth_pct

    from monthly
)

select * from with_lag