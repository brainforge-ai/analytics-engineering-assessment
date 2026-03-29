.PHONY: docs

docs:
	uv run dbt deps
	uv run dbt docs generate
	uv run dbt docs serve
