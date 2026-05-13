/*
-- Singular test: No null unit_price should exist in staging
-- Fails if any product_id includes a null value for unit_price
*/

select
    product_id
    ,name
    ,category
    ,unit_price
from {{ ref('stg_products') }}
WHERE 
    unit_price is null