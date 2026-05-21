with source as (

    select * from {{ ref('products') }}

)

select
    cast(product_id as varchar)    as product_id,
    cast(name       as varchar)    as product_name,
    cast(category   as varchar)    as category,
    try_cast(unit_price as double) as unit_price
from source
