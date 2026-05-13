-- Singular test: The (country, year_month) combination must be unique in the
-- revenue mart. Rows returned here mean the incremental delete+insert did not
-- clean up prior rows before reinserting, causing double-counted revenue.

select
    country,
    year_month,
    count(*) as row_count
from {{ ref('fct_monthly_revenue') }}
group by country, year_month
having count(*) > 1