-- Trim staged order fields to the downstream essentials and enrich with customer data.

-- ref tables
with orders as (

    select
        order_id,
        customer_id,
        order_date,
        status,
        total_amount,
        currency,
        updated_at,
        is_valid_order
    from {{ ref('stg_orders') }}

),

customers as (

    select
        customer_id,
        country_code,
        country_name
    from {{ ref('stg_customers') }}

),

-- join customer country attributes to orders
orders_enriched as (

    select
        orders.order_id,
        orders.customer_id,
        customers.country_code,
        customers.country_name,
        orders.order_date,
        orders.status,
        orders.total_amount,
        orders.currency,
        orders.updated_at,
        orders.is_valid_order
    from orders
    left join customers
        on orders.customer_id = customers.customer_id

)

-- final intermediate contract for downstream country revenue and monthly reporting
select
    order_id,
    customer_id,
    country_code,
    country_name,
    order_date,
    -- derive a reusable YYYY-MM key from the cleaned order date
    cast(strftime(order_date, '%Y-%m') as varchar) as order_year_month,
    -- derive month-start to make monthly joins and comparisons easier
    cast(date_trunc('month', order_date) as date) as order_month_start,
    status,
    total_amount,
    currency,
    updated_at,
    is_valid_order
from orders_enriched
