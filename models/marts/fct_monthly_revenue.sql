{{
  config(
    materialized='incremental',
    incremental_strategy='append'
  )
}}

-- Monthly revenue by country. Grain: one row per (country, year_month).
-- Incremental append: each run inserts only months not yet present in the mart.
-- For corrections to historical months, run with --full-refresh.
with new_orders as (

    select
        order_id,
        country,
        year_month,
        total_amount,
        updated_at
    from {{ ref('int_orders_enriched') }}
    where is_revenue_recognizable = true
      and country is not null

    {% if is_incremental() %}
      and year_month > (select max(year_month) from {{ this }})
    {% endif %}

),

aggregated as (

    select
        country,
        year_month,
        sum(total_amount)  as total_revenue,
        count(*)           as order_count,
        avg(total_amount)  as avg_order_value,
        max(updated_at)    as last_updated_at,
        current_timestamp  as built_at
    from new_orders
    group by 1, 2

)

select
    country,
    year_month,
    total_revenue,
    order_count,
    avg_order_value,
    last_updated_at,
    built_at
from aggregated
