/*
 * Singular data test: completed orders in inter_orders must have a positive total.
 *
 * Fails when: status is 'completed' and total_amount is less than or equal to zero.
 * (Null amounts are not selected by `<= 0`; use a separate not-null test if required.)
 */

select
    order_id
    ,customer_id
    ,country
    ,order_date
    ,order_year_month
    ,order_monthend_date
    ,status
    ,is_revenue
    ,total_amount
    ,currency
    ,updated_at
from {{ ref('inter_orders') }}
WHERE 
    status = 'completed'
    AND total_amount <= 0