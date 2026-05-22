-- models/marts/fct_monthly_revenue.sql

{{
    config(
        materialized='incremental',
        unique_key=['country', 'order_year_month'],
        incremental_strategy='delete+insert'
    )
}}

{#
  Incremental strategy: delete+insert on composite key (country, order_year_month).

  On full refresh: aggregates all revenue-eligible orders across all months.

  On incremental run:
    1. Identify which order_year_months contain any order updated since the last
       run (updated_at > max watermark stored in this table).
    2. Delete existing aggregate rows for those (country, order_year_month) pairs.
    3. Re-insert fully recomputed aggregates for those months only.

  This is correct for periodic snapshot facts: a single late-arriving update
  changes the aggregate for the entire month bucket, so the whole bucket must
  be recomputed — partial aggregation would produce wrong totals.

  max_updated_at stores the watermark per row for the next incremental run.

  Known limitation: if an order transitions from eligible to ineligible status
  (e.g. completed → refunded) after the initial load, a full-refresh is needed
  to correct the aggregate. Incremental runs only detect new/updated eligible orders.
#}

with

eligible_orders as (

    select
        country,
        order_year_month,
        order_id,
        total_amount,
        updated_at

    from {{ ref('int_orders') }}

    where is_revenue_eligible = true
      and country is not null

    {% if is_incremental() %}

        -- Re-aggregate any order_year_month (by order_date) that has received
        -- new or updated orders since the last run.
        -- Uses order_year_month (from order_date), not strftime(updated_at),
        -- because an order's aggregate bucket is its order_date month —
        -- not the month it was last updated.
        and order_year_month in (

            select distinct order_year_month
            from {{ ref('int_orders') }}
            where is_revenue_eligible = true
              and country is not null
              and updated_at > (
                  select coalesce(
                      max(max_updated_at),
                      cast('1900-01-01' as date)
                  )
                  from {{ this }}
              )

        )

    {% endif %}

),

final as (

    select
        country,
        order_year_month,
        round(sum(total_amount), 2)   as total_revenue,
        count(order_id)               as order_count,
        round(avg(total_amount), 2)   as avg_order_value,
        max(updated_at)     as max_updated_at

    from eligible_orders
    group by country, order_year_month

)

select * from final
