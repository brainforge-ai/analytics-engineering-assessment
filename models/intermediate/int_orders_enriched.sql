{{ config(materialized='view') }}

-- Joins clean orders to customer attributes and encodes the single, central
-- "is this revenue?" business rule. Every downstream revenue / cohort metric
-- reads from here so the rule lives in exactly one place.
--
-- Revenue recognition assumption (revisit with Finance):
--   completed, shipped    -> recognised
--   pending               -> NOT recognised (may still cancel)
--   cancelled, refunded   -> NOT recognised
--
-- A more sophisticated model would treat refunded as a negative contra-revenue
-- entry, but that requires a refunded_amount the source doesn't currently expose.

with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

)

select
    o.order_id,
    o.customer_id,
    c.country,
    c.email,
    c.email_is_shared,
    o.order_date,
    o.year_month,
    o.status,
    o.total_amount,
    o.currency,
    o.updated_at,
    (o.status in ('completed', 'shipped')) as is_revenue_recognizable
from orders o
left join customers c
  on o.customer_id = c.customer_id
