/*
  stg_orders — Cleaned and deduplicated orders.

  Data quality decisions:
  ─────────────────────────────────────────────────────────────────────────────
  BAD DATES (filter out entirely):
    • Rows where order_date = 'invalid_date' — literal string, unparseable.
    • Rows where order_date parses to before 2023-01-01 — seed context is
      Jan–Mar 2024. Year-2020 records are clearly corrupt/stale.
    • Rows where order_date is in the future (> current_date) — system error. 
        Did Not Include a hardcoded filter for scalability reasons. 
        Orders after March 2024 are either pending or refunded.
    We filter rather than quarantine because including bad dates in a monthly
    revenue aggregation would silently attribute revenue to wrong months.

  NULL AMOUNTS (preserve, do not filter):
    • ~19 pending orders have no total_amount. This is legitimate — an order
      can exist before it is invoiced. We keep these rows and leave the amount
      as NULL. The downstream revenue mart excludes them via the
      is_valid_revenue_order flag. Filtering here would lose the order record
      entirely, which would break order-count metrics.

  DUPLICATES (deduplicate by updated_at, then amount):
    • ord_0501 appears twice with the same updated_at but different amounts
      (346.04 and 692.08). We partition by order_id and order by updated_at
      DESC, then total_amount DESC as a tiebreaker. This keeps the higher
      amount, which is the most conservative revenue assumption. In production
      this would need source-of-truth clarification.
*/

with source as (
    select * from {{ ref('orders') }}
),

deduplicated as (
    select
        order_id,
        customer_id,
        order_date,
        status,
        total_amount,
        currency,
        updated_at,
        row_number() over (
            partition by order_id
            order by
                case
                    when updated_at is not null
                     and updated_at != 'invalid_date'
                    then try_cast(updated_at as date)
                    else null
                end desc nulls last,
                try_cast(
                    nullif(trim(cast(total_amount as varchar)), '') as double
                ) desc nulls last
        ) as row_num
    from source
),

typed as (
    select
        order_id,
        customer_id,
        -- try_cast returns NULL for unparseable strings like 'invalid_date'
        try_cast(order_date as date)                               as order_date,
        order_date                                                 as order_date_raw,
        status,
        -- Empty string in CSV is read as empty string, not NULL
        -- nullif converts empty string to NULL before casting
        try_cast(
            nullif(trim(cast(total_amount as varchar)), '') as double
        )                                                          as total_amount,
        upper(trim(currency))                                      as currency,
        try_cast(updated_at as date)                               as updated_at
    from deduplicated
    where row_num = 1
),

quality_classified as (
    select
        *,
        case
            when order_date_raw = 'invalid_date'  then 'invalid_string'
            when order_date is null               then 'unparseable'
            when order_date > current_date        then 'future_date'
            when order_date < '2023-01-01'        then 'too_old'
            else 'valid'
        end as date_quality_flag
    from typed
),

final as (
    select
        order_id,
        customer_id,
        order_date,
        status,
        total_amount,
        currency,
        updated_at
    from quality_classified
    where date_quality_flag = 'valid'
)

select * from final