select
    country
    ,currency
    ,year_month
    ,
from 
    {{ref('fct_monthly_revenue')}}
where 
    total_revenue is null