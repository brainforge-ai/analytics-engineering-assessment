
{% set start_range_date %}
(select (min(order_date) - INTERVAL 29 DAY) from {{ ref('inter_orders') }})
{% endset %}
{% set end_range_date %}
(select max(order_date) from {{ ref('inter_orders') }})
{% endset %}


with date_spine_cte as (

    -- Generate a list of dates between 
{{ dbt_utils.date_spine(
    datepart="day",
    start_date=start_range_date | trim,
    end_date=end_range_date | trim
) }}

),

countries as (
    select 
        country
    from {{ ref('inter_orders') }}
    group by 
        1
),

prep_fact as (
    SELECT
        spine.report_date
        ,spine.country
        ,agg.currency
        ,agg.total_amount
    FROM (
            select 
                -- Cast the generated column to a standard date format
                cast(date_day as date) as report_date
                ,country
            from date_spine_cte
                CROSS JOIN countries
        ) spine
        left join ( 
            SELECT
                order_date
                ,country
                ,currency
                ,sum(total_amount) as total_amount
            FROM {{ref('inter_orders')}}
            group by 
                1,2,3
        ) agg
        on spine.report_date = agg.order_date 
        and spine.country = agg.country
)

SELECT
    report_date
    ,country
    ,currency
    ,total_amount as daily_revenue
    ,sum(total_amount) 
        over (partition by country, currency order by report_date ASC ROWS BETWEEN 29 PRECEDING AND 0 FOLLOWING) 
    as thirty_day_rolling_revenue
FROM 
    prep_fact
GROUP BY 
    1,2,3,4
ORDER BY
    country desc, report_date desc