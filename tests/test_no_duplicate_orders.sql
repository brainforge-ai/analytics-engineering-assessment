-- Singular test: After deduplication in stg_orders, each order_id must appear
-- exactly once. Any rows returned here mean the deduplication window logic
-- has a gap that needs fixing.

select
    order_id,
    count(*) as row_count
from {{ ref('stg_orders') }}
group by order_id
having count(*) > 1