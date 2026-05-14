-- TODO: Implement incremental mart per CHALLENGE.md sect 3.3.
-- Required columns: country, year_month, total_revenue, order_count, avg_order_value
-- Use is_incremental() and merge strategy based on updated_at.
-- Also build one complex metric (sect 3.4): rolling 30d, MoM growth, or cohort.
-- Replace the placeholder below with your implementation.
/*
select
  cast(null as varchar) as country,
  cast(null as varchar) as year_month,
  cast(null as double) as total_revenue,
  cast(null as bigint) as order_count,
  cast(null as double) as avg_order_value
where 1 = 0
*/


SELECT
    country
    ,currency
    ,order_year_month
    ,round(sum(total_amount),2) as total_revenue
    ,count(distinct order_id) as order_count
    ,round((sum(total_amount) / count(distinct order_id)),2) as avg_order_value
FROM 
    {{ref('inter_orders')}}
group by 
    1,2,3
order by 
    1 asc, 2 asc, 3 desc