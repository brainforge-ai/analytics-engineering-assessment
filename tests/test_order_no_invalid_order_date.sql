/*
 * Singular data test: non-null order_date values cast to a DATE.
 *
 * Fails when: order_date is not null but try_cast(order_date as date) is null (DuckDB).
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
    order_date is not null
    AND try_cast(order_date as DATE) is null
