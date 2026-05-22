---
name: dimensional-modeling
description: Use when designing or implementing dimensional models — fact tables, dimension tables, star schemas, SCDs, grain definitions, bus matrices, or dbt-based warehouse layer architecture.
metadata:
  author: ae-assessment
---

# Dimensional Modeling Expert

## Core Philosophy

Dimensional modeling (Kimball methodology) optimizes analytical queries for business users. The triad of every design decision:

1. **Business process** — what event or activity are we measuring?
2. **Grain** — what does one row represent? (declare it first, always)
3. **Dimensions** — what context describes the event?
4. **Facts** — what numeric measures capture the event?

> The grain declaration is the single most important design decision. Every other choice flows from it.

---

## This Project's Schema (Reference)

**Seeds (raw layer):**
- `raw.orders` — order_id, customer_id, order_date, status, total_amount, currency, updated_at
- `raw.customers` — customer_id, email, country, created_at
- `raw.products` — product_id, name, category, unit_price

**Target dimensional schema:**

```
                    ┌──────────────┐
                    │  dim_date    │
                    │  (date_id)   │
                    └──────┬───────┘
                           │
┌──────────────┐   ┌───────┴──────┐   ┌──────────────┐
│ dim_customers ├───┤  fct_orders  ├───┤  dim_products │
│ (customer_key)│   │  (one row    │   │ (product_key) │
└──────────────┘   │   per order) │   └──────────────┘
                   └──────────────┘
                          │
                   ┌──────┴───────────────────────────┐
                   │ fct_monthly_revenue (periodic     │
                   │ snapshot — one row per country/mo)│
                   └──────────────────────────────────┘
```

---

## Fact Table Types

### 1. Transaction Fact (most common)
One row per discrete business event. Additive measures.

```sql
-- fct_orders: grain = one row per order
select
    {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_key,
    order_id,                          -- degenerate dimension (natural key from source)
    customer_key,                      -- FK → dim_customers
    product_key,                       -- FK → dim_products (if applicable)
    order_date_key,                    -- FK → dim_date
    status,                            -- junk/low-cardinality attribute
    total_amount,                      -- additive fact
    1 as order_count                   -- implicit fact (useful for aggregation)
from ...
```

### 2. Periodic Snapshot Fact
One row per grain period, even if nothing happened. Captures state at interval end.

```sql
-- fct_monthly_revenue: grain = one row per (country, year_month)
-- This grain means: NEVER have two rows with the same country + year_month
select
    country,
    year_month,              -- 'YYYY-MM'
    total_revenue,           -- SUM of valid order amounts
    order_count,             -- COUNT of valid orders
    avg_order_value          -- total_revenue / order_count
from ...
group by country, year_month
```

### 3. Accumulating Snapshot Fact
One row per business process instance that updates as it progresses (e.g., order fulfillment pipeline). Use when tracking pipeline lag.

### 4. Factless Fact
Records events with no numeric measure (e.g., which products were viewed, promotions applied).

---

## Dimension Table Types

### Standard Dimension

```sql
-- dim_customers
select
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key,
    customer_id,             -- natural/business key — keep for traceability
    email,
    country,
    created_at,
    current_timestamp as dbt_updated_at
from {{ ref('stg_customers') }}
```

### SCD Type 1 — Overwrite (no history)
Current value overwrites old. Use when history is not needed or the change is a correction.

```sql
-- Just update in place. In dbt: materialized as table with full refresh.
-- Or incremental with unique_key to upsert.
{{ config(materialized='incremental', unique_key='customer_key') }}
```

### SCD Type 2 — Add Row (full history)
New row added for each change. Enables point-in-time correctness.

```sql
-- dbt snapshot (preferred approach for SCD Type 2)
{% snapshot dim_customers_history %}
{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at',
    )
}}
select * from {{ ref('stg_customers') }}
{% endsnapshot %}
```

**Key SCD Type 2 columns:**
- `dbt_scd_id` — surrogate key for each version
- `dbt_valid_from` — when this version became active
- `dbt_valid_to` — when this version was superseded (NULL = current)
- `dbt_is_current` — boolean flag for current record

### SCD Type 3 — Add Column (limited history)
Add `previous_country`, `current_country`. Rarely useful; prefer Type 2.

### SCD Type 6 — Hybrid (Type 1 + 2 + 3)
Current value columns on all historical rows for easy current-value access without joining.

---

## Star Schema vs Snowflake Schema

| | Star | Snowflake |
|---|---|---|
| Dimension normalization | Flat (denormalized) | Normalized (sub-dimensions) |
| Query complexity | Simple joins | More joins |
| Query performance | Faster | Slower (more joins) |
| Storage | More redundancy | Less redundancy |
| BI tool compatibility | Excellent | Moderate |

**Default: star schema.** Snowflake schema is rarely worth the join complexity in modern columnar databases (DuckDB, Snowflake, BigQuery, Redshift).

---

## Surrogate Keys

Always generate surrogate keys for dimension tables (not natural keys as FKs in fact tables). Provides:
- Independence from source system changes
- Support for SCD Type 2 (multiple versions of same entity)
- Consistent join performance

```sql
-- With dbt_utils
{{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key

-- Native DuckDB (no package needed)
md5(cast(customer_id as varchar)) as customer_key

-- For composite keys
md5(cast(customer_id as varchar) || '-' || cast(order_date as varchar)) as order_key
```

---

## Grain — Common Mistakes

| Mistake | Problem | Fix |
|---|---|---|
| Fact rows at different grains mixed | Aggregations double-count | Declare grain up front; one grain per fact table |
| Periodic snapshot missing zero-months | Gaps break MoM calcs | LEFT JOIN to dim_date to fill gaps |
| Measure that's not additive added to snapshot | Wrong aggregation | Use AVG/MAX in fact, not SUM |
| Semi-additive fact (balance) summed across time | Wrong total | Use MAX or window function across time dim |

---

## Bus Matrix (Planning Tool)

Map business processes (rows) against conformed dimensions (columns):

| Business Process | Date | Customer | Product | Order Status |
|---|---|---|---|---|
| Order placed | ✓ | ✓ | ✓ | ✓ |
| Monthly revenue | ✓ | ✓ (country only) | — | — |
| Product inventory | ✓ | — | ✓ | — |

Use this before writing any SQL. Shared dimensions across rows = conformed dimensions.

---

## Conformed Dimensions

A dimension shared across multiple fact tables with the same definition and grain. Example: `dim_date` used by both `fct_orders` and `fct_monthly_revenue`.

```sql
-- dim_date: the universal conformed dimension
-- Generate with a macro or seed; never join on raw date strings
select
    cast(strftime(calendar_date, '%Y%m%d') as integer) as date_key,
    calendar_date,
    year,
    quarter,
    month,
    week_of_year,
    day_of_week,
    day_name,
    strftime(calendar_date, '%Y-%m') as year_month,
    (dayofweek(calendar_date) in (0, 6)) as is_weekend
from ...
```

---

## dbt Layer Architecture

```
raw (seeds/sources)
  └── staging (stg_*)       -- 1:1 with source, cleaned, typed, renamed
        └── intermediate (int_*)  -- business logic, joins, enrichment
              └── marts
                    ├── dimensions (dim_*)   -- materialized as table
                    └── facts (fct_*)        -- materialized as table or incremental
```

### Naming Conventions

| Layer | Prefix | Example |
|---|---|---|
| Staging | `stg_` | `stg_orders`, `stg_customers` |
| Intermediate | `int_` | `int_orders` |
| Dimension | `dim_` | `dim_customers`, `dim_products`, `dim_date` |
| Fact (transaction) | `fct_` | `fct_orders` |
| Fact (snapshot/agg) | `fct_` | `fct_monthly_revenue` |

---

## Incremental Patterns for Tables

### Append-only (event log, immutable)
```sql
{{ config(materialized='incremental', incremental_strategy='append') }}

{% if is_incremental() %}
where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
```

### Upsert / Merge (mutable facts, like this project's orders)
```sql
{{
    config(
        materialized='incremental',
        unique_key=['country', 'year_month'],   -- grain columns
        incremental_strategy='delete+insert'    -- DuckDB native
    )
}}

{% if is_incremental() %}
-- Reprocess any month that has new/updated orders
where year_month in (
    select distinct strftime(order_date, '%Y-%m')
    from {{ ref('stg_orders') }}
    where updated_at > (select max(_loaded_at) from {{ this }})
)
{% endif %}
```

### Full refresh (small dimensions, reference data)
```sql
{{ config(materialized='table') }}
-- No incremental logic needed; always rebuild
```

---

## Rolling Window Metrics

```sql
-- 30-day rolling revenue — use window function on transaction fact
select
    order_date,
    country,
    sum(total_amount) over (
        partition by country
        order by order_date
        range between interval 29 days preceding and current row
    ) as rolling_30d_revenue
from {{ ref('fct_orders') }}
```

```sql
-- Month-over-month growth — use LAG on periodic snapshot
select
    country,
    year_month,
    total_revenue,
    lag(total_revenue) over (
        partition by country
        order by year_month
    ) as prior_month_revenue,
    round(
        100.0 * (total_revenue - lag(total_revenue) over (partition by country order by year_month))
        / nullif(lag(total_revenue) over (partition by country order by year_month), 0),
        2
    ) as mom_growth_pct
from {{ ref('fct_monthly_revenue') }}
```

---

## Data Quality in Dimensional Models

### Null Foreign Keys
Facts should never have null FKs — add a "Unknown" or "Not Applicable" row to each dimension:

```sql
-- dim_customers: always include a catch-all row
union all
select
    '-1' as customer_key,
    'UNKNOWN' as customer_id,
    'Unknown' as email,
    'Unknown' as country,
    null as created_at
```

### Degenerate Dimensions
Source system keys (order_id, invoice_number) stored directly on the fact with no separate dimension table. Appropriate when the key has no descriptive attributes.

### Junk Dimensions
Low-cardinality flags and indicators (is_rush, payment_method, channel) combined into one dimension to avoid fact table clutter. Each unique combination = one row.

---

## DuckDB-Specific Notes

```sql
-- Date formatting (DuckDB)
strftime(order_date, '%Y-%m')         -- 'YYYY-MM'
strftime(order_date, '%Y%m%d')        -- 'YYYYMMDD' (date key)
date_trunc('month', order_date)       -- first day of month

-- Deduplication with row_number (DuckDB supports this natively)
qualify row_number() over (
    partition by order_id
    order by updated_at desc
) = 1

-- Incremental strategy for DuckDB: use 'delete+insert' or 'append'
-- DuckDB does not support 'merge' in dbt-duckdb < 1.8
```

---

## Checklist: Before Writing Any SQL

1. [ ] Declared the grain (one row per ___)?
2. [ ] Identified all measures — are they fully additive, semi-additive, or non-additive?
3. [ ] Identified all dimensions — do conformed dimensions already exist?
4. [ ] Chosen fact table type (transaction / periodic snapshot / accumulating snapshot)?
5. [ ] Decided SCD strategy for each dimension?
6. [ ] Confirmed surrogate key generation approach?
7. [ ] Planned incremental strategy (if applicable)?
8. [ ] Added grain to the model's YAML description?
