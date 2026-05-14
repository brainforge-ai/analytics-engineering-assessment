SELECT
    order_id
    ,customer_id
    ,order_date
    ,strftime(order_date, '%Y-%m') as order_year_month
    ,last_day(order_date) as order_monthend_date
    ,status
    ,total_amount
    ,currency
    ,updated_at
FROM 
    {{ref('stg_orders')}}
