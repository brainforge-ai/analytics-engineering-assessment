-- Singular test: No duplicate order_ids should exist in staging
-- Fails if any order_id appears more than once

select
    order_id,
    count(*) as duplicate_count
from {{ ref('stg_orders') }}
group by 1
having count(*) > 1
