
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