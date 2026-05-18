{{
  config(
    materialized='incremental',
    unique_key=['country', 'year_month'],
    incremental_strategy='merge',
    on_schema_change='append_new_columns'
  )
}}

-- Monthly revenue by country.  One row per (country, year_month).
--
-- Incremental strategy
-- --------------------
-- This is an *aggregate* mart, so a single late-arriving order changes the
-- whole month's totals.  The pattern below:
--
--   1. Find every (country, year_month) touched by any row updated since the
--      last run, by looking at int_orders_enriched.updated_at.
--   2. Re-aggregate **all** orders for those months in full -- partial sums
--      are not safe to add.
--   3. Merge on (country, year_month) so existing rows are overwritten
--      atomically; brand-new months are inserted.
--
-- Watermark column `last_updated_at` is stored on the mart itself, so the
-- next run does a single cheap `max()` against {{ this }} instead of having
-- to track state externally.
--
-- When does this strategy stop being optimal?
--   At ~10^7 orders / month, re-aggregating any touched month becomes the
--   bottleneck.  Next step: introduce a daily-grain pre-aggregate
--   (fct_daily_revenue) and roll *that* up monthly, so the unit of recompute
--   shrinks from one month to one day.

with new_orders as (

    select *
    from {{ ref('int_orders_enriched') }}
    where is_revenue_recognizable = true
      and country is not null

    {% if is_incremental() %}
      and year_month in (
          select distinct year_month
          from {{ ref('int_orders_enriched') }}
          where updated_at > (
              select coalesce(max(last_updated_at), date '1900-01-01')
              from {{ this }}
          )
      )
    {% endif %}

),

aggregated as (

    select
        country,
        year_month,
        sum(total_amount)             as total_revenue,
        count(*)                      as order_count,
        avg(total_amount)             as avg_order_value,
        max(updated_at)               as last_updated_at,
        current_timestamp             as built_at
    from new_orders
    group by 1, 2

)

select * from aggregated
