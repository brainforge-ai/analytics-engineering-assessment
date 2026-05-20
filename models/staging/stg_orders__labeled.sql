-- Assigns a dq_reason to every order row. NULL means the row is clean.
-- Downstream: stg_orders selects WHERE dq_reason IS NULL,
--             stg_orders__quarantine selects WHERE dq_reason IS NOT NULL.
with source as (

    select * from {{ ref('orders') }}

),

parsed as (

    select
        cast(order_id    as varchar)     as order_id,
        cast(customer_id as varchar)     as customer_id,
        cast(order_date  as varchar)     as order_date_raw,
        try_cast(order_date as date)     as order_date,
        cast(status      as varchar)     as status,
        try_cast(total_amount as double) as total_amount,
        cast(currency    as varchar)     as currency,
        try_cast(updated_at as date)     as updated_at
    from source

),

ranked as (

    -- Deterministic dedupe: latest update wins; ties broken by higher amount
    -- so revenue is never silently under-counted on a tied update.    select
    
    select *,
        row_number() over (
            partition by order_id
            order by updated_at desc nulls last,
                     total_amount desc nulls last
        ) as row_num
    from parsed

),

labeled as (

    select
        order_id,
        customer_id,
        order_date_raw,
        order_date,
        status,
        total_amount,
        currency,
        updated_at,
        case
            when row_num > 1
                then 'duplicate_order_id'
            when order_date is null
                then 'invalid_date'
            when order_date > date '{{ var("max_valid_order_date") }}'
                then 'future_date'
            when order_date < date '{{ var("min_valid_order_date") }}'
                then 'stale_date'
            when status = 'completed'
                 and (total_amount is null or total_amount <= 0)
                then 'completed_with_bad_amount'
            when total_amount is null and status <> 'pending'
                then 'null_amount_unexpected'
            else null
        end as dq_reason
    from ranked

)

select
    order_id,
    customer_id,
    order_date_raw,
    order_date,
    status,
    total_amount,
    currency,
    updated_at,
    dq_reason
from labeled
