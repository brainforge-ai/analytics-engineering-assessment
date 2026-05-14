
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