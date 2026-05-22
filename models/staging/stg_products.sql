-- models/staging/stg_products.sql

with

source as (

    select * from {{ ref('products') }}

),

final as (

    select

        ---------- ids
        cast(product_id as varchar) as product_id,

        ---------- strings
        name             as product_name,
        category,

        ---------- numerics
        cast(unit_price as decimal(10, 2)) as unit_price

    from source

)

select * from final
