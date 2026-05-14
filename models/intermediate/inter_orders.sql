SELECT
    ordr.order_id
    ,ordr.customer_id
    ,customer.country
    ,ordr.order_date
    ,strftime(ordr.order_date, '%Y-%m') as order_year_month
    ,last_day(ordr.order_date) as order_monthend_date
    ,ordr.status
    ,ordr.total_amount
    ,ordr.currency
    ,ordr.updated_at
FROM 
    {{ref('stg_orders')}} as ordr
    left join {{ref('stg_customers')}} as customer
        on ordr.customer_id = customer.customer_id