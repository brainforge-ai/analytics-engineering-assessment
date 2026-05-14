select
    country
    ,currency
    ,year_month
    ,latest_updated_at
    ,total_revenue
    ,order_count
    ,avg_order_value
from 
    {{ref('fct_monthly_revenue')}}
where 
    total_revenue is null