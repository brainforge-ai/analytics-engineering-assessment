/*
 * Singular data test: monthly revenue grain is unique.
 *
 * Fails when: more than one row exists for the same country, currency, and year_month.
 */

select
    country
    ,currency
    ,year_month
    ,COUNT(*)
from 
    {{ref('fct_monthly_revenue')}}
GROUP BY 
    1,2,3
HAVING COUNT(*) = 1