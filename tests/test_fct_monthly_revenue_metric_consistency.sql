-- Singular business logic test

select *
from {{ ref('fct_monthly_revenue') }}

-- Compare total_revenue to expected revenue from avg_order_value * order_count.
where abs(
    total_revenue
    - (avg_order_value * order_count)
) > (
    -- Allow 1 cent of rounding tolerance per order.
    order_count * 0.01
)
