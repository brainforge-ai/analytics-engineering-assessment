with cleaned as (

    select
        cast(customer_id as varchar)        as customer_id,
        lower(trim(cast(email as varchar))) as email,
        cast(country as varchar)            as country,
        try_cast(created_at as date)        as created_at
    from {{ ref('customers') }}

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
        c.customer_id,
        c.email,
        c.country,
        c.created_at,
        (s.email is not null) as email_is_shared
    from cleaned c
    left join shared_emails s on c.email = s.email

)

select
    customer_id,
    email,
    country,
    created_at,
    email_is_shared
from flagged
qualify row_number() over (
    partition by customer_id
    order by created_at desc nulls last
) = 1
