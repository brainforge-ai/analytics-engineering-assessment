-- Clean product seed records with light normalization and final typed output.

-- ref tables
with products_raw as (

    select
        product_id,
        name,
        category,
        unit_price
    from {{ ref('products') }}

),

-- normalize raw string fields used downstream
products_normalized as (

    select
        product_id,
        name as product_name,
        category,
        cast(unit_price as varchar) as unit_price_raw
    from products_raw

)

select
    cast(product_id as varchar) as product_id,
    cast(trim(product_name) as varchar) as product_name,
    cast(trim(category) as varchar) as category,
    cast(try_cast(unit_price_raw as double) as double) as unit_price
from products_normalized
