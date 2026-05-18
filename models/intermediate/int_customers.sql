-- Enriches stg_customers with email_is_shared: TRUE when the same email
-- appears against more than one customer_id (shared inbox / household / ingest bug).
-- Downstream models can filter or group on this flag; we never drop these rows.
with customers as (

    select
        customer_id,
        email,
        country,
        created_at
    from {{ ref('stg_customers') }}

),
shared_emails as (

    select email
    from customers
    where email is not null
    group by 1
    having count(*) > 1

),

flagged as (

    select
        customers.customer_id,
        customers.email,
        customers.country,
        customers.created_at,
        (shared_emails.email is not null) as email_is_shared
    from customers
    left join shared_emails
        on customers.email = shared_emails.email

)

select
    customer_id,
    email,
    country,
    created_at,
    email_is_shared
from flagged
