/*
  stg_products — Cleaned products reference table.

  Minimal cleaning needed: seed is clean. We cast types and add a guard
  against missing product_id or non-positive prices (which would indicate a
  data load error and would corrupt any order-level price joins).
*/

with source as (
    select * from {{ ref('products') }}
),

final as (
    select
        product_id,
        trim(name)                 as name,
        trim(category)             as category,
        cast(unit_price as double) as unit_price
    from source
    where product_id is not null
      and unit_price > 0
)

select * from final