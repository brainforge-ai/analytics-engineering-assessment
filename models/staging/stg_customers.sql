-- Clean customer seed records and surface duplicate-email metadata at the customer_id grain.
-- clean and dedupe customer records to one row per customer_id
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

-- count of customer id by email
email_counts as (

    select
        email,
        count(*) as email_record_count
    from customers_normalized
    group by 1

),

-- rank records within each normalized email group so we can flag a primary row
-- identify primary customer_id rows based on email.
-- choose id with earliest created_at date, then customer_id
customer_email_ranked as (

    select
        customer_id,
        email,
        country_code,
        created_at,
        row_number() over (
            partition by email
            order by created_at asc, customer_id asc
        ) as email_record_rank
    from customers_normalized
    -- row_number() is a window function - explain I have not used these, so I added this note for myself
    -- row_number() assigns 1, 2, 3... within each email group
    -- partition by email restarts that numbering for each distinct email
    -- order by created_at/customer_id decides which row gets rank 1

)

select
    cast(customer_email_ranked.customer_id as varchar) as customer_id,
    cast(customer_email_ranked.email as varchar) as email,
    cast(customer_email_ranked.country_code as varchar) as country_code,
    cast(country_codes.country_name as varchar) as country_name,
    cast(customer_email_ranked.created_at as date) as created_at,
    cast(email_counts.email_record_count as integer) as email_record_count,
    cast(email_counts.email_record_count > 1 as boolean)
        as is_duplicate_email_record,
    cast(customer_email_ranked.email_record_rank = 1 as boolean)
        as is_primary_email_record
from customer_email_ranked
left join email_counts
    on customer_email_ranked.email = email_counts.email
left join country_codes
    on customer_email_ranked.country_code = country_codes.country_code
