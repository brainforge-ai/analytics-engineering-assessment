{{ config(materialized='view') }}

-- customer_id is the PK and is unique in the seed; we still apply a defensive
-- dedupe so a duplicated source row never silently inflates the customer base.
-- Duplicate emails are present in the seed (shared across distinct customer_ids).
-- We don't merge or drop those rows: the right call (real person? household?
-- ingest bug?) sits with the business. We flag them via email_is_shared so
-- analytics can choose to treat shared-email customers separately.

with source as (

    select * from {{ ref('customers') }}

),

cleaned as (

    select
        cast(customer_id as varchar)              as customer_id,
        lower(trim(cast(email as varchar)))       as email,
        cast(country as varchar)                  as country,
        try_cast(created_at as date)              as created_at
    from source

),

shared_emails as (

    select email
    from cleaned
    where email is not null
    group by 1
    having count(*) > 1

),

flagged as (

    select
        c.*,
        (s.email is not null) as email_is_shared
    from cleaned c
    left join shared_emails s
      on c.email = s.email

)

select *
from flagged
qualify row_number() over (
    partition by customer_id
    order by created_at desc nulls last
) = 1
