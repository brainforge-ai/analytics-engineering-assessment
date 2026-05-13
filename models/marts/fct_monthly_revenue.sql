/*
  fct_monthly_revenue — Incremental revenue fact table.
*/

{{
    config(
        materialized='incremental',
        unique_key=['country', 'year_month'],
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

with base as (
    select * from {{ ref('int_orders_enriched') }}
    where country is not null
),

{% if is_incremental() %}

affected_months as (
    select distinct country, year_month
    from base
    where updated_at > (
        -- Safe check for first run
        select coalesce(max(last_updated_at), cast('1900-01-01' as date))
        from {{ this }}
        where false  -- This makes the subquery return no rows on first run
    )
),

orders_in_scope as (
    select b.*
    from base b
    inner join affected_months am
        on b.country = am.country
       and b.year_month = am.year_month
),

{% else %}

-- Full refresh on first run
orders_in_scope as (
    select * from base
),

{% endif %}

monthly_aggregates as (
    select
        country,
        year_month,
        sum(case when is_valid_revenue_order then total_amount else 0 end) as total_revenue,
        count(case when is_valid_revenue_order then order_id end)         as order_count,
        avg(case when is_valid_revenue_order then total_amount end)       as avg_order_value,
        max(updated_at)                                                   as last_updated_at
    from orders_in_scope
    group by country, year_month
)

select
    country,
    year_month,
    round(total_revenue, 2)   as total_revenue,
    order_count,
    round(avg_order_value, 2) as avg_order_value,
    last_updated_at
from monthly_aggregates