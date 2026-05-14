/*
 * Singular data test: non-null updated_at values cast to a DATE.
 *
 * Fails when: updated_at is not null but try_cast(updated_at as date) is null (DuckDB).
 */

select
    order_id
    ,customer_id
    ,order_date
    ,status
    ,total_amount
    ,currency
    ,updated_at
from {{ ref('stg_orders') }}
WHERE
    updated_at is not null
    AND try_cast(updated_at as DATE) is null

