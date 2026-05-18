-- Duplicate emails are flagged in int_customers, not here.
-- The right resolution (same person / household / ingest bug) is a business call.
with source as (

    select * from {{ ref('customers') }}

)

select
    cast(customer_id as varchar)          as customer_id,
    lower(trim(cast(email as varchar)))   as email,
    cast(country as varchar)              as country,
    try_cast(created_at as date)          as created_at
from source
