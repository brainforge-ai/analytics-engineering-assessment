-- TODO: Implement incremental mart per CHALLENGE.md sect 3.3.
-- Required columns: country, year_month, total_revenue, order_count, avg_order_value
-- Use is_incremental() and merge strategy based on updated_at.
-- Also build one complex metric (sect 3.4): rolling 30d, MoM growth, or cohort.
-- Replace the placeholder below with your implementation.

select
  cast(null as varchar) as country,
  cast(null as varchar) as year_month,
  cast(null as double) as total_revenue,
  cast(null as bigint) as order_count,
  cast(null as double) as avg_order_value
where 1 = 0
