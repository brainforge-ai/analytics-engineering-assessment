# David Rose Submission README

Notes/ writeup for Brainforge analytics engineering assessment submission.

## Developer Setup & Run

Setup
```bash
uv sync
source .venv/bin/activate
```

Run dbt
```bash
dbt seed
dbt run
dbt test
```

## Deliverable Checklist Progress

- [ ] Staging models handle all listed data quality issues: bad dates, nulls, and duplicates.
- [ ] Incremental mart `fct_monthly_revenue` has the correct grain and required columns.
- [ ] A complex metric is implemented: rolling metric, month-over-month growth, or cohort analysis.
- [ ] At least 4 tests are included: uniqueness, `not_null`, relationship, and a custom data quality test.
- [ ] A singular test covers a business rule.
- [ ] All models are documented with business-friendly descriptions.
- [ ] Data quality assumptions and incremental strategy are documented.
- [ ] `dbt seed`, `dbt run`, and `dbt test` all succeed.
- [ ] The README or PR description explains how to run the project and the key design decisions.