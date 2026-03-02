-- Singular test: Completed orders should have positive total_amount
-- Fails if any completed order has amount <= 0

select
    order_id,
    total_amount,
    status
from {{ ref('stg_orders') }}
where status = 'completed'
  and (total_amount <= 0 or total_amount is null)
