# CLAUDE.md — AE Assessment Project

## Project overview

Analytics engineering assessment using dbt Core 1.11.11 + DuckDB. All models run locally — no database server required. Seeds are pre-generated CSVs in `seeds/`.

## Running dbt

Always prefix dbt commands with `DBT_PROFILES_DIR=.` and use the venv executable:

```bash
DBT_PROFILES_DIR=. .venv/bin/dbt seed          # load CSVs into DuckDB
DBT_PROFILES_DIR=. .venv/bin/dbt build          # run + test all models
DBT_PROFILES_DIR=. .venv/bin/dbt build --full-refresh   # full rebuild of incremental models
DBT_PROFILES_DIR=. .venv/bin/dbt compile --select <model>  # inspect compiled SQL
```

## Project structure

```
seeds/          → raw CSVs (orders, customers, products)
models/
  staging/      → stg_orders, stg_customers, stg_products (views)
  intermediate/ → int_orders (view; enriches orders with country + derived fields)
  marts/        → fct_monthly_revenue (incremental table), fct_mom_revenue (view)
tests/          → singular SQL tests (kept as business rule documentation)
analyses/       → local scratch files and notes (gitignored)
macros/         → custom generic tests
```

## Schema docs

Schema YAML files follow the `_<layer>_models.yml` naming convention:
- `models/staging/_staging_models.yml`
- `models/intermediate/_intermediate_models.yml`
- `models/marts/_marts_models.yml`

## Key design decisions

- **Revenue eligibility** is controlled by the project variable `revenue_eligible_statuses` in `dbt_project.yml`. Currently `['completed', 'shipped']`. Use `var('revenue_eligible_statuses')` — never hardcode statuses in SQL.
- **Incremental strategy** on `fct_monthly_revenue` is `delete+insert`. The affected-months subquery uses `year_month` (derived from `order_date`), NOT `strftime(updated_at)` — an order's bucket is its order date month, not its update month.
- **`fct_mom_revenue` is a VIEW** intentionally. LAG() must operate over the full time series; computing it inside the incremental model would produce wrong percentages on partial runs.
- **All 100 customer_ids are retained** in `stg_customers` (including 4 duplicate-email pairs) to preserve FK integrity with orders. Use `is_primary_record = true` only for unique-customer analysis, never to filter the orders join.

## Packages

- `dbt-labs/dbt_utils` 1.3.3
- `metaplane/dbt_expectations` 0.10.10

dbt_expectations uses `strictly: true` (not `strictly_min`) for exclusive bounds. All third-party test arguments must be nested under an `arguments:` key (dbt 1.11 requirement).

## DuckDB file locking

The database file is `analytics.duckdb`. If the DBCode VSCode extension has it open, dbt commands will fail with a lock error. Disconnect DBCode before running dbt, or configure the DBCode connection as read-only.

## Local-only files (gitignored)

- `analyses/` — collection of scratch SQL and Gideon's prep interview notes
