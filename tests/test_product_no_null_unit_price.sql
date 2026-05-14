/*
 * Singular data test: product catalog prices are present.
 *
 * Fails when: unit_price is null on stg_products.
 */

select
    product_id
    ,name
    ,category
    ,unit_price
from {{ ref('stg_products') }}
WHERE 
    unit_price is null