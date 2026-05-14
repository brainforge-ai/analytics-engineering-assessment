/*
 * Singular data test: non-null customer emails are unique in staging.
 *
 * Fails when: the same email appears on more than one stg_customers row.
 */
 
select
    email,
    count(*) as duplicate_count
from {{ ref('stg_customers') }}
where email is not null
group by 1
having count(*) > 1
