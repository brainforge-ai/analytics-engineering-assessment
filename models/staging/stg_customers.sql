-- Clean and deduplicate customer seed records to one row per normalized email.

-- ref tables
with customers_raw as (

    select
        customer_id,
        email,
        country,
        created_at
    from {{ ref('customers') }}

),

-- normalize customers_raw 
customers_normalized as (

    select
        customer_id,
        created_at,
        case
            when upper(trim(country)) = 'UK' then 'GB'
            else upper(trim(country))
        end as country_code,
        lower(trim(email)) as email
    from customers_raw

),

country_codes as (

    select
        country_code,
        country_name
    from {{ ref('country_codes') }}

),

-- get email counts by customer
email_counts as (

    select
        email,
        count(*) as email_record_count
    from customers_normalized
    group by 1

),

-- keep one customer record per normalized email
-- keep earlierst customer record, per created_at date
deduplicated_customers as (

    select
        customer_id,
        email,
        country_code,
        created_at
    from customers_normalized
    -- row_number() is a window function - explain I have not used these, so I added this note for myself
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
    cast(deduplicated_customers.country_code as varchar) as country_code,
    cast(country_codes.country_name as varchar) as country_name,
    cast(deduplicated_customers.created_at as date) as created_at,
    cast(email_counts.email_record_count > 1 as boolean) as has_duplicate_email,
    cast(email_counts.email_record_count as integer) as duplicate_email_count
from deduplicated_customers
left join email_counts
    on deduplicated_customers.email = email_counts.email
left join country_codes
    on deduplicated_customers.country_code = country_codes.country_code
