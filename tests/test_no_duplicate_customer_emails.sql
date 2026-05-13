/*
-- Singular test: No duplicate emails should exist in staging
-- Fails if any email is shared by more than one customer
*/

select
    email,
    count(*) as duplicate_count
from {{ ref('stg_customers') }}
where email is not null
group by 1
having count(*) > 1
