-- models/staging/stg_customers.sql

with

source as (

    select * from {{ ref('customers') }}

),

final as (

    select

        ---------- ids
        cast(customer_id as varchar) as customer_id,

        ---------- strings
        email,
        country,

        ---------- timestamps
        cast(created_at as date) as created_at,

        ---------- dedup flag
        -- TRUE for the earliest-created customer per email address.
        -- Source data has 4 pairs sharing duplicate emails.
        -- All 100 customer_ids are preserved for FK integrity with stg_orders.
        -- Downstream unique-customer analysis should filter is_primary_record = true.
        row_number() over (
            partition by email
            order by created_at asc, customer_id asc
        ) = 1 as is_primary_record

    from source

)

select * from final
