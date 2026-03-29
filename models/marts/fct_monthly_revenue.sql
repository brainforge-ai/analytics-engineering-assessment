-- Monthly revenue mart at the grain of one row per country per year_month.

-- model-specific unique key - the grain for incremental updates
{{ config(
    unique_key=['country', 'year_month']
) }}

-- ref tables
with valid_orders as (

    select
        country_name,
        order_year_month,
        total_amount,
        updated_at
    from {{ ref('int_orders_enriched') }}
    where is_valid_order

),

-- Read the latest processed updated_at already present in the mart.
-- Use that value as the cutoff for deciding what changed since the last run.
current_mart_max_updated_at as (

    -- On incremental runs, read the current cutoff from the existing mart rows.
    {% if is_incremental() %}
        select coalesce(max(existing_mart.max_order_updated_at), cast('{{ var("order_updated_at_cutoff_date") }}' as date)) as max_order_updated_at
        from {{ this }} as existing_mart
    -- Full refresh runs use the configured fallback date, so all rows are in scope.
    {% else %}
        select cast('{{ var("order_updated_at_cutoff_date") }}' as date) as max_order_updated_at
    {% endif %}

),

-- Identify the [country + year_month] combinations to recompute because their underlying orders changed.
country_months_to_replace as (

    -- List the country_name + order_year_month buckets whose underlying orders changed.
    select distinct
        changed_source_orders.country_name,
        changed_source_orders.order_year_month
    from valid_orders as changed_source_orders

    -- On incremental runs, build the final list of buckets (country + year_month) to recompute 
    {% if is_incremental() %}
        where changed_source_orders.updated_at >= (
            select current_mart_max_updated_at.max_order_updated_at
            from current_mart_max_updated_at
        )
    {% endif %}

),

-- Pull all orders where country-month buckets is to be recomputed
orders_scoped as (

    -- Get all valid orders in each affected bucket
    select
        source_orders.country_name,
        source_orders.order_year_month,
        source_orders.total_amount,
        source_orders.updated_at
    from valid_orders as source_orders

    -- On incremental runs, limit the scope to buckets in country_months_to_replace.
    -- On full refresh runs, all valid orders are in scope.
    {% if is_incremental() %}
        inner join country_months_to_replace
            on
                source_orders.country_name = country_months_to_replace.country_name
                and source_orders.order_year_month = country_months_to_replace.order_year_month
    {% endif %}

),

-- Calculate raw country-month revenue metrics before final currency formatting.
aggregated_revenue_raw as (

    select
        country_name as country,
        -- noqa: RF04 because year_month is the required output column name
        order_year_month as year_month, -- noqa: RF04
        sum(total_amount) as total_revenue,
        count(*) as order_count,
        avg(total_amount) as avg_order_value,
        -- our Mart "last updated" field used in incremental update runs
        max(updated_at) as max_order_updated_at
    from orders_scoped
    group by 1, 2

),

-- Apply currency typeing and rounding for final table
aggregated_revenue as (

    select
        country,
        year_month,
        cast(round(total_revenue, 2) as decimal(18, 2)) as total_revenue,
        order_count,
        cast(round(avg_order_value, 2) as decimal(18, 2)) as avg_order_value,
        max_order_updated_at
    from aggregated_revenue_raw

)

select
    country,
    year_month,
    total_revenue,
    order_count,
    avg_order_value,
    max_order_updated_at
from aggregated_revenue
