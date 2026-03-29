-- Clean and deduplicate order seed records while surfacing data quality flags.

-- ref tables
with orders_raw as (

    select
        order_id,
        customer_id,
        order_date,
        status,
        total_amount,
        currency,
        updated_at
    from {{ ref('orders') }}

),

-- normalize orders_raw 
orders_normalized as (

    select
        order_id,
        customer_id,
        order_date as order_date_raw,
        updated_at as updated_at_raw,
        cast(total_amount as varchar) as total_amount_raw,
        lower(trim(status)) as status,
        upper(trim(currency)) as currency,
        try_cast(order_date as date) as order_date_parsed,
        try_cast(updated_at as date) as updated_at_parsed
    from orders_raw

),

-- Flag blank/null total_amount values
orders_amounts_flagged as (

    select
        order_id,
        customer_id,
        order_date_raw,
        updated_at_raw,
        total_amount_raw,
        status,
        currency,
        order_date_parsed,
        updated_at_parsed,
        trim(coalesce(total_amount_raw, '')) = '' as has_missing_total_amount,
        try_cast(
            nullif(trim(coalesce(total_amount_raw, '')), '') as double
        ) as total_amount_parsed
    from orders_normalized

),

-- Flag date issues - invalid, future, too-old
orders_dates_flagged as (

    select
        order_id,
        customer_id,
        order_date_raw,
        updated_at_raw,
        total_amount_raw,
        status,
        currency,
        order_date_parsed,
        updated_at_parsed,
        has_missing_total_amount,
        total_amount_parsed,
        order_date_parsed is null as has_invalid_order_date,
        updated_at_parsed is null as has_invalid_updated_at,
        order_date_parsed > date '2024-03-31' as has_future_order_date,
        order_date_parsed < date '2024-01-01' as has_too_old_order_date
    from orders_amounts_flagged

),

-- count duplicate order_ids
order_id_counts as (

    select
        order_id,
        count(*) as order_id_record_count
    from orders_dates_flagged
    group by 1

),

-- keep one order record per order_id, preferring the most recent updated_at
deduplicated_orders as (

    select
        order_id,
        customer_id,
        status,
        currency,
        order_date_raw,
        updated_at_raw,
        total_amount_raw,
        order_date_parsed,
        updated_at_parsed,
        has_missing_total_amount,
        total_amount_parsed,
        has_invalid_order_date,
        has_invalid_updated_at,
        has_future_order_date,
        has_too_old_order_date
    from orders_dates_flagged
    -- 'row_number()' is the window function, and will assign 1, 2, 3... within each order_id group of order id
    -- 'partition by order_id' restarts this numbering for each distinct order id
    -- 'order by' picks most recent order, based on updated_at. Then use amount/customer_id as tie-breaker in case of duplicate timestamp
    -- 'qualify' keeps only the rank-1 row, which is how the dedupe works
    qualify row_number() over (
        partition by order_id
        order by
            updated_at_parsed desc nulls last,
            total_amount_parsed desc nulls last,
            customer_id asc
    ) = 1

),

-- construct order quality flags
orders_flags as (

    select
        deduplicated_orders.order_id,
        deduplicated_orders.customer_id,
        deduplicated_orders.status,
        deduplicated_orders.currency,
        deduplicated_orders.order_date_raw,
        deduplicated_orders.updated_at_raw,
        deduplicated_orders.total_amount_raw,
        deduplicated_orders.order_date_parsed,
        deduplicated_orders.updated_at_parsed,
        deduplicated_orders.has_missing_total_amount,
        deduplicated_orders.total_amount_parsed,
        deduplicated_orders.has_invalid_order_date,
        deduplicated_orders.has_invalid_updated_at,
        deduplicated_orders.has_future_order_date,
        deduplicated_orders.has_too_old_order_date,
        order_id_counts.order_id_record_count,
        deduplicated_orders.status = 'cancelled'
        and coalesce(deduplicated_orders.total_amount_parsed, 0) <= 1
            as has_near_zero_cancelled_amount
    from deduplicated_orders
    left join order_id_counts
        on deduplicated_orders.order_id = order_id_counts.order_id

)

select
    cast(order_id as varchar) as order_id,
    cast(customer_id as varchar) as customer_id,
    cast(order_date_parsed as date) as order_date,
    cast(status as varchar) as status,
    cast(total_amount_parsed as double) as total_amount,
    cast(currency as varchar) as currency,
    cast(updated_at_parsed as date) as updated_at,
    cast(order_id_record_count > 1 as boolean) as had_duplicate_order_id,
    cast(order_id_record_count as integer) as duplicate_order_id_count,
    cast(has_invalid_order_date as boolean) as has_invalid_order_date,
    cast(has_invalid_updated_at as boolean) as has_invalid_updated_at,
    cast(has_missing_total_amount as boolean) as has_missing_total_amount,
    cast(has_future_order_date as boolean) as has_future_order_date,
    cast(has_too_old_order_date as boolean) as has_too_old_order_date,
    cast(has_near_zero_cancelled_amount as boolean)
        as has_near_zero_cancelled_amount,
    cast(
        not has_invalid_order_date
        and not has_invalid_updated_at
        and not has_future_order_date
        and not has_too_old_order_date
        and not has_missing_total_amount
        as boolean
    ) as is_valid_order
from orders_flags
