/*
 * Singular data test: order_id is unique in staging.
 *
 * Fails when: the same order_id appears on more than one stg_orders row.
 */
 
select
    order_id,
    count(*) as duplicate_count
from {{ ref('stg_orders') }}
group by 1
having count(*) > 1
