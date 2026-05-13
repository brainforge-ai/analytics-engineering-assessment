/*
  int_orders_enriched — Joins validated orders with customer attributes.
*/

with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

enriched as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.updated_at,
        strftime(o.order_date, '%Y-%m')               as year_month,
        year(o.order_date)                            as order_year,
        month(o.order_date)                           as order_month,
        o.status,
        o.total_amount,
        o.currency,
        c.email                                       as customer_email,
        c.country,
        c.created_at                                  as customer_created_at,
        case
            when o.status in ('completed', 'shipped')
             and o.total_amount is not null
             and o.total_amount > 0
            then true
            else false
        end                                           as is_valid_revenue_order,
        datediff('day', c.created_at, o.order_date)  as customer_tenure_days
    from orders o
    left join customers c
        on o.customer_id = c.customer_id
)

select * from enriched