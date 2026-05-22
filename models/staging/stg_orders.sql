-- models/staging/stg_orders.sql

with

source as (

    select * from {{ ref('orders') }}

),

date_parsed as (

    select

        order_id,
        customer_id,
        -- TRY_CAST returns NULL for unparseable strings (e.g. 'invalid_date').
        try_cast(order_date  as date)   as order_date,
        status,
        -- Preserve NULL amounts as NULL (do not coerce to 0).
        -- NULL total_amount only appears on status = 'pending' orders.
        cast(total_amount as decimal(10, 2))    as total_amount,
        currency,
        -- updated_at: valid orders may have updated_at in Apr 2024+
        -- (legitimately updated after the Q1 order window). Filter only on
        -- order_date, not updated_at.
        try_cast(updated_at  as date)   as updated_at

    from source

),

date_filtered as (

    -- Retain only Q1 2024 orders.
    -- Removes: 'invalid_date' rows (TRY_CAST → NULL), 2020-01-01 outliers,
    --          and any order_date beyond 2024-03-31 (future dates).
    select *
    from date_parsed
    where order_date is not null
      and order_date >= cast('2024-01-01' as date)
      and order_date <= cast('2024-03-31' as date)

),

final as (

    -- Deduplicate order_ids. ord_0501 appears twice with identical updated_at
    -- but different total_amount (346.04 vs 692.08). Secondary sort on
    -- total_amount DESC keeps the higher amount (treated as corrected value).
    select
        order_id,
        customer_id,
        order_date,
        status,
        total_amount,
        currency,
        updated_at
    from date_filtered
    qualify row_number() over (
        partition by order_id
        order by updated_at desc, total_amount desc nulls last, customer_id asc
    ) = 1

)

select * from final
