-- Staging model for customer seed data.
-- Strategy for duplicate emails:
--   - Normalize email values before deduping.

--   - Expose duplicate flags/counts so downstream models and docs can describe the cleanup.

with customers_raw as (

    select *
    from {{ ref('customers') }}

),

-- identify patients with multiple emails
email_counts as (

    select
        lower(trim(email)) as email,
        count(*) as email_record_count
    from customers_raw
    group by 1

),

-- keep one customer record per normalized email
-- keep earliest customer record, per created_at date
deduplicated_customers as (

    select
        customer_id,
        lower(trim(email)) as email,
        country,
        created_at
    from customers_raw
    qualify row_number() over (
            partition by lower(trim(email))
            order by created_at asc, customer_id asc
        ) = 1

)

select
    cast(c.customer_id as varchar) as customer_id,
    cast(c.email as varchar) as email,
    cast(upper(trim(c.country)) as varchar) as country,
    cast(c.created_at as date) as created_at,
    cast(email_counts.email_record_count > 1 as boolean) as has_duplicate_email,
    cast(email_counts.email_record_count as integer) as duplicate_email_count
from deduplicated_customers as c
left join email_counts
    on c.email = email_counts.email
