/*
 * Singular data test: completed orders carry a positive total_amount.
 *
 * Fails when: status is 'completed' and total_amount is null, zero, or negative.
 */

select
    order_id,
    total_amount,
    status
from {{ ref('stg_orders') }}
where status = 'completed'
  and (total_amount <= 0 or total_amount is null)
