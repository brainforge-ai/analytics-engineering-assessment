-- models/intermediate/int_orders.sql

with

stg_orders as (

    select

        order_id,
        customer_id,
        order_date,
        status,
        total_amount,
        currency,
        updated_at

    from {{ ref('stg_orders') }}

),

stg_customers as (

    select

        customer_id,
        country

    from {{ ref('stg_customers') }}

),

final as (

    select

        stg_orders.order_id,
        stg_orders.customer_id,
        stg_orders.order_date,
        stg_orders.status,
        stg_orders.total_amount,
        stg_orders.currency,
        stg_orders.updated_at,

        ---------- from customers
        stg_customers.country,

        ---------- derived
        -- YYYY-MM format sorts correctly alphabetically (= chronologically).
        strftime(stg_orders.order_date, '%Y-%m')             as order_year_month,

        -- Revenue eligibility: statuses defined in var('revenue_eligible_statuses').
        -- Pending (null amount), cancelled (near-zero), refunded = not eligible.
        stg_orders.status in ({{ "'" + var('revenue_eligible_statuses') | join("', '") + "'" }})
            and stg_orders.total_amount > 0                   as is_revenue_eligible

    from stg_orders
    inner join stg_customers
        on stg_orders.customer_id = stg_customers.customer_id

)

select * from final
