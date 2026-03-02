-- TODO: Implement staging model for orders.
-- Handle data quality issues per CHALLENGE.md sect 3.1:
--   - Invalid/future/old dates (filter or flag)
--   - Null amounts (filter or default)
--   - Duplicate order_ids (keep most recent by updated_at)
-- Replace the pass-through below with your implementation.

select * from {{ ref('orders') }}
