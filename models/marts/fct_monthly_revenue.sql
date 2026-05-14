-- [ X ] TODO: Implement incremental mart per CHALLENGE.md sect 3.3.
-- Required columns: country, year_month, total_revenue, order_count, avg_order_value
-- Use is_incremental() and merge strategy based on updated_at.

{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['country', 'currency', 'year_month'],
    )
}}

/*
Incremental strategy (updated_at, merge)

- Grain is (country, currency, month). Incremental does not mean “only rows with
  recent updated_at” in the final GROUP BY — that would omit unchanged orders in the
  same month and break totals.
- Instead: find month-buckets that are new or stale (any order in that bucket has
  updated_at greater than latest_updated_at stored on the mart row for that bucket,
  or the mart has no row yet). Re-read ALL inter_orders rows for those buckets, then
  aggregate. Merge upserts full month rows so new and changed months are recomputed.
*/

with inter as (
    select * from {{ ref('inter_orders') }}
),

{% if is_incremental() %}

touched_buckets as (
    select 
        o.country
        , o.currency
        , o.order_year_month
    from inter as o
    where not exists (
        select 1
        from {{ this }} as t
        where t.country = o.country
            and t.currency = o.currency
            and t.year_month = o.order_year_month
    )
    group by
         1,2,3

    union

    select  
        o.country
        , o.currency
        , o.order_year_month
    from inter as o
    inner join {{ this }} as t
        on t.country = o.country
        and t.currency = o.currency
        and t.year_month = o.order_year_month
    where o.updated_at > t.latest_updated_at
    group by 
        1,2,3
),

scoped as (
    select o.*
    from inter as o
    inner join touched_buckets as tb
        on o.country = tb.country
        and o.currency = tb.currency
        and o.order_year_month = tb.order_year_month
    where o.is_revenue = 1
),

{% else %}

scoped as (
    select * from inter
    where is_revenue = 1
),

{% endif %}

final as (
    select
        country,
        currency,
        order_year_month as year_month,
        max(updated_at) as latest_updated_at,
        round(sum(total_amount), 2) as total_revenue,
        count(distinct order_id) as order_count,
        round(
            sum(total_amount) / nullif(count(distinct order_id), 0),
            2
        ) as avg_order_value
    from scoped
    group by country, currency, order_year_month
)

select *
from final
order by country asc, currency asc, year_month desc
