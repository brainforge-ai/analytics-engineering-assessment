# Analytics Engineering Assessment — Ayoade Adegbite

A dbt + DuckDB analytics engineering project built to solve a realistic e-commerce data challenge. This repository demonstrates:
- **Data quality handling** through a label-and-split pattern that makes bad data observable
- **Incremental modeling** for monthly revenue aggregates
- **Complex business metrics** via cohort analysis
- **Testing and documentation** for warehouse reliability

---

## Video walkthrough

A short walkthrough of this solution is included in the repository:

[![Watch the walkthrough video](./recording-ae-assessment-slide-ayoade-adegbite-thumbnail.png)](https://youtu.be/XdpuzofjMaM)


## Repository structure

```
.
├── CHALLENGE.md
├── README.md
├── dbt_project.yml
├── profiles.yml
├── macros/
│   └── positive_amount.sql
├── scripts/
│   └── generate_seed_data.py
├── seeds/
│   ├── customers.csv
│   ├── orders.csv
│   └── products.csv
├── models/
│   ├── staging/
│   │   ├── _staging.yml
│   │   ├── stg_customers.sql
│   │   ├── stg_orders.sql
│   │   ├── stg_orders__labeled.sql
│   │   ├── stg_orders__quarantine.sql
│   │   └── stg_products.sql
│   ├── intermediate/
│   │   ├── _intermediate.yml
│   │   └── int_orders_enriched.sql
│   └── marts/
│       ├── _marts.yml
│       ├── fct_monthly_revenue.sql
│       └── fct_customer_cohorts.sql
└── tests/
    ├── test_completed_orders_positive_amount.sql
    └── test_no_duplicate_orders.sql
```

---

## What this solution includes

### Staging layer
- `stg_orders` — clean, deduplicated orders after staging DQ labeling
- `stg_orders__labeled` — deduplicates orders and assigns a `dq_reason` to every row (NULL = clean)
- `stg_orders__quarantine` — rejected rows (where `dq_reason IS NOT NULL`) routed here for DQ monitoring
- `stg_customers` — type-cast, normalize email, and flag `email_is_shared`; no business-resolution logic
- `stg_products` — type-cast only

### Intermediate layer
- `int_orders_enriched` — clean orders joined to customer attributes; encodes `is_revenue_recognizable` once for all downstream marts

### Marts
- `fct_monthly_revenue` — incremental (append strategy) monthly revenue by `country` and `year_month`
- `fct_customer_cohorts` — cohort retention analysis: active customers and revenue by cohort month and offset

### Macros
- `macros/positive_amount.sql` — generic test asserting a column value is > 0

---

## Key project decisions

### Data quality: label and split at the staging layer

Rather than silently filtering bad rows, `stg_orders__labeled` assigns a `dq_reason` to every order:

| Reason code | Condition |
|---|---|
| `duplicate_order_id` | `row_num > 1` after dedup window |
| `invalid_date` | `order_date` could not be parsed |
| `future_date` | `order_date > max_valid_order_date` var |
| `stale_date` | `order_date < min_valid_order_date` var |
| `completed_with_bad_amount` | `status = completed` and `total_amount` is null or ≤ 0 |
| `null_amount_unexpected` | `total_amount` is null on any non-pending status |

Clean rows flow to `stg_orders` (`dq_reason IS NULL`, `row_num = 1`) and then to `int_orders_enriched`.
Rejected rows flow to `stg_orders__quarantine` (`dq_reason IS NOT NULL`), keeping the count by reason visible for dashboards and alerting.

`pending` orders with null amounts are kept — revenue recognition is handled downstream.

### Customer email deduplication

`stg_customers` flags shared emails via `email_is_shared`. The rows are never dropped; the right resolution (same person / household / ingest bug) is a business decision, not an engineering one.

### Intermediate enrichment

`int_orders_enriched` encodes `is_revenue_recognizable` (`status IN ('completed', 'shipped')`) once, so all marts share a single definition.

The join to `stg_customers` uses `LEFT JOIN` deliberately: if a customer row is unexpectedly missing, the order is preserved with `NULL` country rather than silently dropped. `fct_monthly_revenue` already filters `country IS NOT NULL`, so an orphaned order becomes a visible anomaly rather than a hidden revenue loss.

### Incremental mart

`fct_monthly_revenue` uses `incremental_strategy = 'append'`. Each run inserts only months not yet present in the mart:

```sql
{% if is_incremental() %}
  and year_month > (select max(year_month) from {{ this }})
{% endif %}
```

For corrections to historical months, run with `--full-refresh`.

### Complex metric: cohort analysis

`fct_customer_cohorts` implements first-purchase cohort retention. Cohort was chosen over:
- Month-over-month growth — only ~2 data points across ~3 months of data
- 30-day rolling — too jittery for small per-country volumes

---

## How to run

```bash
DBT_PROFILES_DIR=. dbt seed && dbt run && dbt test
```

### Run individual models

```bash
DBT_PROFILES_DIR=. dbt run --select stg_orders
DBT_PROFILES_DIR=. dbt run --select stg_orders__labeled
DBT_PROFILES_DIR=. dbt run --select stg_orders__quarantine
DBT_PROFILES_DIR=. dbt run --select stg_customers
DBT_PROFILES_DIR=. dbt run --select int_orders_enriched
DBT_PROFILES_DIR=. dbt run --select fct_monthly_revenue
DBT_PROFILES_DIR=. dbt run --select fct_customer_cohorts
```

### Run by layer

```bash
DBT_PROFILES_DIR=. dbt run --select staging
DBT_PROFILES_DIR=. dbt run --select intermediate
DBT_PROFILES_DIR=. dbt run --select marts
```

### Test a single model

```bash
DBT_PROFILES_DIR=. dbt test --select int_orders_enriched
```

---

## Notes

- `vars` in `dbt_project.yml` define the valid `order_date` window (`min_valid_order_date`, `max_valid_order_date`), so date anomalies are treated as data quality issues rather than depending on `current_date`.
- The project has no external dbt package dependencies.
- The dataset is intentionally small (~1,000 orders); the model comments document where strategy changes would be appropriate at larger volumes.
