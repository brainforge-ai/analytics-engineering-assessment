# Analytics Engineering Challenge — Interview Assignment

This challenge evaluates **data modeling, SQL, dbt, testing, and documentation** using seed data in `seeds/` (orders, customers, products). You will use **dbt Core with DuckDB** so everything runs locally with no database server.

**Key focus areas:**
- Handling realistic data volume (~1,000 orders, data quality issues)
- Incremental model logic
- Complex business metrics (revenue aggregation, rolling calculations)
- Data quality testing and documentation

---

## 1. Setup

- **Runtime:** dbt Core + DuckDB. Install with: `pip install dbt-duckdb` (or use a venv).
- **Seeds:** CSVs in `seeds/` — `orders.csv`, `customers.csv`, `products.csv`. Generate with `python scripts/generate_seed_data.py` if needed.
- **Profile:** `profiles.yml` is configured for a local DuckDB database (`analytics.duckdb` in the project directory). Run from the project root with `DBT_PROFILES_DIR=.` so dbt uses this profile, e.g. `DBT_PROFILES_DIR=. dbt seed && dbt run && dbt test`.

---

## 2. Data and metadata (reference)

### orders
- `order_id` (PK), `customer_id` (FK → customers), `order_date`, `status`, `total_amount`, `currency`, `updated_at`.
- **Data quality issues to handle:**
  - Invalid date formats (`invalid_date`)
  - Future dates (2024-04+ when data is Jan-Mar)
  - Very old dates (2020)
  - Null or empty `total_amount` for some pending orders
  - Near-zero amounts for cancelled orders
  - Duplicate `order_id` (same ID, different amounts)

### customers
- `customer_id` (PK), `email`, `country`, `created_at`.
- **Data quality issues:** Duplicate emails across customers.

### products
- `product_id` (PK), `name`, `category`, `unit_price`.

---

## 3. Tasks

### 3.1 Staging models with data quality handling

- Build **staging** models that read from the seeds and **handle data quality issues**:
  - Filter out or quarantine bad dates (invalid, future, too old).
  - Handle null amounts appropriately (decide: filter, default, or flag).
  - Deduplicate orders (keep the most recent by `updated_at` when `order_id` is duplicated).
  - Handle duplicate customer emails (decide strategy: pick one, flag, etc.).
- Document your data quality assumptions in the model descriptions.
- Place models in `models/staging/`.

### 3.2 Intermediate model (optional but recommended)

- Consider an intermediate model that enriches orders with customer attributes and computes derived fields (e.g., order year-month, is_valid order flag).

### 3.3 Incremental mart: Monthly Revenue by Country

Build **one incremental mart** in `models/marts/`:

- **Mart name:** `fct_monthly_revenue`
- **Grain:** One row per country per month (e.g., `2024-01`, `US`).
- **Required columns:**
  - `country` (from customers)
  - `year_month` (YYYY-MM format from order_date)
  - `total_revenue` (sum of valid order amounts)
  - `order_count` (count of valid orders)
  - `avg_order_value` (average per order)
- **Incremental logic:** Use `is_incremental()` to append new/updated records based on `updated_at`. Document your incremental strategy.

### 3.4 Rolling metrics mart (bonus/complex)

Build a second mart OR add to the first (choose one):

- **Option A:** 30-day rolling revenue per country (current date + prior 29 days).
- **Option B:** Month-over-month revenue growth % per country.
- **Option C:** Customer cohort analysis (first order month → subsequent order behavior).

This tests window functions and business metric calculation.

### 3.5 Tests and documentation (strict requirements)

- **Tests:**
  - Uniqueness + not_null on `fct_monthly_revenue` primary key (country + year_month).
  - Relationship test: `customer_id` in orders references customers.
  - Custom/generic test: Assert that `total_amount > 0` for completed orders (data quality test).
  - At least one singular test (SQL test) for a business rule.
- **Documentation:**
  - Business-friendly descriptions for all marts (not just technical).
  - Explain data quality decisions (what you filtered, why).
  - Document the incremental strategy.

---

## 4. Deliverables checklist

- [ ] Staging models handle all listed data quality issues (bad dates, nulls, duplicates).
- [ ] Incremental mart `fct_monthly_revenue` with correct grain and columns.
- [ ] Rolling metric OR MoM growth OR cohort analysis (choose one complex metric).
- [ ] At least 4 tests: uniqueness, not_null, relationship, custom data quality test.
- [ ] Singular test for a business rule.
- [ ] All models documented with business-friendly descriptions.
- [ ] Data quality assumptions and incremental strategy documented.
- [ ] `dbt seed`, `dbt run`, and `dbt test` all succeed.
- [ ] README or PR description explains how to run and your key design decisions.

---

## 5. Evaluation criteria

| Area | Description |
|------|-------------|
| **Data quality handling** | Proper filtering/cleaning of bad dates, nulls, duplicates; defensive modeling. |
| **Incremental logic** | Correct use of `is_incremental()`, merge strategy, and documentation. |
| **SQL / dbt quality** | Readable SQL, appropriate use of refs/sources, CTEs, window functions. |
| **Business metrics** | Correct revenue aggregation, rolling/MoM/cohort calculations. |
| **Testing & docs** | Comprehensive tests including data quality; clear business descriptions. |
| **Completeness** | All deliverables met; project runs end-to-end. |
| **Presentation** | If Loom provided: clarity of walkthrough and design rationale. |

---

## 6. Out of scope

- No ingestion or orchestration; seeds are provided.
- No BI tool or dashboard; we evaluate the dbt project, SQL, and docs only.

Good luck.
