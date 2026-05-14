/*
 * Singular data test: monthly revenue fact has no null measure.
 *
 * Fails when: total_revenue is null for any (country, currency, year_month) row.
 */

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