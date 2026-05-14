-- TODO: Implement staging model for orders.
-- Handle data quality issues per CHALLENGE.md sect 3.1:
--   - Invalid/future/old dates (filter or flag)
--   - Null amounts (filter or default)
--   - Duplicate order_ids (keep most recent by updated_at)
-- Replace the pass-through below with your implementation.


select
    order_id
    ,customer_id
    ,order_date
    ,status
    ,min(total_amount) as total_amount  -- in case of same datetimestamp, resolve to lower value for sake of the customer who may experience an undercharge vs overcharge. dbt tests and tight audit loop to remediate. 
    ,currency
    ,updated_at
from (
    select 
        order_id
        ,customer_id
        ,try_strptime(trim(order_date::varchar), '%Y-%m-%d')::date as order_date
        ,status
        ,total_amount
        ,currency
        ,try_strptime(trim(updated_at::varchar), '%Y-%m-%d')::date as updated_at
        ,max(try_strptime(trim(order_date::varchar), '%Y-%m-%d')::date) over (partition by order_id order by updated_at desc rows between unbounded preceding and unbounded following) as max_updated_at
    from {{ source('raw', 'orders') }}
)
where 
    order_date = max_updated_at
group by 
    1,2,3,4,6,7