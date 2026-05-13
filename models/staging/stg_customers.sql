/*
  stg_customers — Cleaned and deduplicated customers.

  Data quality decision — duplicate emails:
    A small number of customers share the same email address (test data artifact).
    Strategy: keep the customer with the lowest customer_id, which represents the
    earliest registration. This gives a deterministic single record per email and
    prevents join fan-out when orders reference a customer_id whose email also
    belongs to another customer_id.

    Alternative considered: flag all duplicates and exclude them. Rejected because
    it would orphan valid orders from those customer_ids in the revenue mart.
*/

with source as (
    select * from {{ ref('customers') }}
),

deduplicated as (
    select
        customer_id,
        lower(trim(email))       as email,
        upper(trim(country))     as country,
        cast(created_at as date) as created_at,
        row_number() over (
            partition by lower(trim(email))
            order by customer_id asc   -- lowest (earliest) customer_id wins
        ) as row_num
    from source
),

final as (
    select
        customer_id,
        email,
        country,
        created_at
    from deduplicated
    where row_num = 1
)

select * from final