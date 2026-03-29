# David Rose Submission README

Notes/ writeup for Brainforge analytics engineering assessment submission.

## Developer Setup & Run

Setup
```bash
uv sync --group dev
source .venv/bin/activate
uv run pre-commit install
```

## Deliverable Checklist Progress

- [x] Staging models handle all listed data quality issues: bad dates, nulls, and duplicates.
- [x] Incremental mart `fct_monthly_revenue` has the correct grain and required columns.
- [x] A complex metric is implemented: rolling metric, month-over-month growth, or cohort analysis.
- [x] At least 4 tests are included: uniqueness, `not_null`, relationship, and a custom data quality test.
- [x] A singular test covers a business rule.
    - test 'tests/test_fct_monthly_revenue_metric_consistency.sql'
- [x] All models are documented with business-friendly descriptions.
    - All models have corresponding .yml.
    - Reviewed and cleaned up descriptions to be "business-friendly"
- [x] Data quality assumptions and incremental strategy are documented.
    -- see "source_data_quality_assumptions" meta in each staging table's corresponding .yml file.
- [x] `dbt seed`, `dbt run`, and `dbt test` all succeed.
- [x] The README or PR description explains how to run the project and the key design decisions.
    -- see PR