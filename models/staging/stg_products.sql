{{ config(materialized='view') }}

-- This model casts types and renames `name` to the more explicit `product_name` so downstream joins are unambiguous.

with source as (

    select * from {{ ref('products') }}

)

select
    cast(product_id as varchar)        as product_id,
    cast(name       as varchar)        as product_name,
    cast(category   as varchar)        as category,
    try_cast(unit_price as double)     as unit_price
from source
