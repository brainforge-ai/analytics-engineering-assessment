-- Deduplication of order_ids happens in int_orders__labeled (row_num = 1 filter).
-- This test verifies that int_orders_enriched, which applies that filter, has no duplicates.
select
    order_id,
    count(*) as duplicate_count
from {{ ref('int_orders_enriched') }}
group by 1
having count(*) > 1
