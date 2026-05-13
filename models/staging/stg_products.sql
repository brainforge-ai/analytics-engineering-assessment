-- TODO: Implement staging model for products.
-- See CHALLENGE.md sect 3.1. Minimal cleaning needed for this seed.
-- Replace the pass-through below with your implementation.

select
    product_id
    ,name
    ,category
    ,unit_price
from {{ source('raw', 'products') }}
