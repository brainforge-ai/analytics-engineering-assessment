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

)

select
    order_id,
    customer_id,
    order_date_raw,
    order_date,
    status,
    total_amount,
    currency,
    updated_at
from parsed
