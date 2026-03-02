# Analytics Engineering Assessment

Interview challenge for analytics engineering candidates at Brainforge. This assessment evaluates **data quality handling, incremental modeling, complex SQL metrics, testing, and documentation** using a realistic e‑commerce dataset with intentional quality issues.

---

## Overview

You will build an analytics layer that handles real-world data quality problems:
- **Staging:** Clean and deduplicate ~1,000 orders with bad dates, null amounts, and duplicates
- **Incremental mart:** `fct_monthly_revenue` (country × month grain) with proper merge logic
- **Complex metrics:** Rolling 30-day revenue OR month-over-month growth OR cohort analysis (choose one)
- **Testing:** Data quality tests, relationship tests, custom business rule tests

The task uses **dbt + DuckDB** so everything runs locally.

**Full instructions:** [CHALLENGE.md](CHALLENGE.md) — read this first.

---

## Repository structure

```
.
├── CHALLENGE.md          # Full task list and deliverables
├── README.md             # This file
├── dbt_project.yml       # dbt project config
├── profiles.yml          # DuckDB profile (local)
├── macros/               # Custom generic tests
│   └── positive_amount.sql
├── scripts/              # Data generation (optional)
│   └── generate_seed_data.py
├── seeds/                # Raw CSVs (~1,000 orders with quality issues)
│   ├── orders.csv
│   ├── customers.csv
│   └── products.csv
├── models/
│   ├── staging/           # Data quality handling (you build)
│   ├── intermediate/      # Optional enrichment
│   └── marts/             # Incremental + rolling metrics (you build)
└── tests/                 # Singular tests for business rules
    ├── test_completed_orders_positive_amount.sql
    └── test_no_duplicate_orders.sql
```

---

## Time expectation

- **Expected effort:** ~4–6 hours (depending on familiarity with dbt, SQL window functions, and incremental logic).
- We evaluate data quality decisions, incremental strategy, SQL quality, tests, and documentation.

---

## Submission instructions

1. **Fork** this repository (you'll receive access once selected for the challenge).
2. Create a new branch named after yourself (e.g. `feature/jane-doe-solution`).
3. Implement your solution in your branch (staging with data quality, incremental mart, rolling metrics, tests, docs).
4. Submit a **Pull Request** to your fork when finished.
5. In the PR description include:
   - How to run the project (from project root: `DBT_PROFILES_DIR=. dbt seed && dbt run && dbt test`).
   - Your data quality decisions (what you filtered, why, any edge cases).
   - Your incremental strategy and why you chose it.
   - Your choice of complex metric (rolling/MoM/cohort) and the SQL approach.
   - Optional: link to a short Loom (5–10 min) walking through your approach.
6. Share the fork link with the recruiting team.

---

## Evaluation criteria

| Area | Description |
|------|-------------|
| **Data quality handling** | Defensive modeling: bad date handling, null amounts, deduplication strategy. Clear rationale documented. |
| **Incremental logic** | Correct use of `is_incremental()`, merge strategy, and performance awareness. |
| **SQL / dbt quality** | Readable SQL, window functions for rolling metrics, CTEs, appropriate use of refs/sources. |
| **Business metrics** | Accurate revenue aggregation; correct rolling/MoM/cohort calculation with proper grain. |
| **Testing & docs** | Data quality tests (uniqueness, relationships, custom tests), business rule tests, clear descriptions. |
| **Completeness** | All deliverables in [CHALLENGE.md](CHALLENGE.md) met; `dbt run` and `dbt test` succeed. |
| **Presentation** | If Loom provided: clarity of walkthrough and design rationale. |

---

## Contact

For technical questions about this challenge, reach out to your contact at Brainforge. Do **not** open public GitHub issues or discussions about the challenge.

---

*This assessment is used by Brainforge for Analytics Engineer candidates (Stage 3). Content owner: Demi / Awaish.*
