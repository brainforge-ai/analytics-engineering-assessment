/*
 * Singular data test: non-null customer created_at casts to a DATE.
 *
 * Fails when: created_at is not null but try_cast(created_at as date) is null (DuckDB),
 * e.g. unparseable strings if the column were widened to varchar upstream.
 */

SELECT 
    customer_id
    ,email
    ,country
    ,created_at 
FROM
    {{ ref('stg_customers') }}
WHERE 
    created_at is not null
    AND try_cast(created_at as DATE) is null
