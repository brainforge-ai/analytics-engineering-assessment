{# Spine bounds: 29 days before first order through last order (DuckDB: date - integer = subtract days). #}
{% set start_range_date %}
(select min(order_date) - 29 from {{ ref('inter_orders') }})
{% endset %}
{% set end_range_date %}
(select max(order_date) + 31 from {{ ref('inter_orders') }})
{% endset %}

with date_spine_cte as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date=start_range_date | trim,
        end_date=end_range_date | trim
    ) }}

),

countries as (
    select country
    from {{ ref('inter_orders') }}
    group by 1
),

currencies as (
    select currency
    from {{ ref('inter_orders') }}
    group by 1
),

prep_fact as (
    select
        spine.report_date,
        spine.country,
        spine.currency,
        coalesce(agg.total_amount,0) as total_amount
    from (
        select
            cast(date_day as date) as report_date
            ,country
            ,currency
        from date_spine_cte
        cross join countries
        cross join currencies
    ) as spine
    left join (
        select
            order_date,
            country,
            currency,
            round(sum(total_amount),2) as total_amount
        from {{ ref('inter_orders') }}
        group by 1, 2, 3
    ) as agg
        on spine.report_date = agg.order_date
        and spine.country = agg.country
        and spine.currency = agg.currency
)

select
    report_date,
    country,
    currency,
    daily_revenue,
    thirty_day_rolling_revenue
from (
    select
        report_date,
        country,
        currency,
        total_amount as daily_revenue,
        round(sum(total_amount) over (
            partition by country, currency
            order by report_date
            rows between 29 preceding and current row
        ),2) as thirty_day_rolling_revenue
    from prep_fact
)
--where thirty_day_rolling_revenue <> 0.0
order by country desc, currency desc, report_date desc
