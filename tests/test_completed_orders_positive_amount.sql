-- Singular test: Every completed order in the intermediate layer must have a
-- positive total_amount. A null or zero amount on a completed order means a
-- revenue record exists but no money was captured — this needs investigation.
-- This tests the intermediate layer, not staging, because staging correctly
-- preserves null amounts for pending orders.

select
    order_id,
    status,
    total_amount
from {{ ref('int_orders_enriched') }}
where status = 'completed'
  and (total_amount is null or total_amount <= 0)