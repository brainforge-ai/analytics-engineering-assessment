-- Clean and deduplicate customer seed records to one row per normalized email.

-- import reference tables
with customers_raw as (

    select
        customer_id,
        email,
        country,
        created_at
    from {{ ref('customers') }}

),

-- initial field normalizaion for logic
customer_email_normalized as (

    select
        customer_id,
        country,
        created_at,
        lower(trim(email)) as email
    from customers_raw

),

-- get email counts by customer
email_counts as (

    select
        email,
        count(*) as email_record_count
    from customer_email_normalized
    group by 1

),

-- keep one customer record per normalized email
-- keep earlierst customer record, per created_at date
deduplicated_customers as (

    select
        customer_id,
        email,
        country,
        created_at
    from customer_email_normalized
    -- row_number() is a window function
    -- row_number() assigns 1, 2, 3... within each email group
    -- partition by email restarts that numbering for each distinct email
    -- order by created_at/customer_id decides which row gets rank 1
    -- qualify keeps only the rank-1 row, which is how the dedupe works
    qualify row_number() over (
        partition by email
        order by created_at asc, customer_id asc
    ) = 1

)

select
    cast(deduplicated_customers.customer_id as varchar) as customer_id,
    cast(deduplicated_customers.email as varchar) as email,
    cast(upper(trim(deduplicated_customers.country)) as varchar) as country,
    cast(deduplicated_customers.created_at as date) as created_at,
    cast(email_counts.email_record_count > 1 as boolean) as has_duplicate_email,
    cast(email_counts.email_record_count as integer) as duplicate_email_count
from deduplicated_customers
left join email_counts
    on deduplicated_customers.email = email_counts.email
