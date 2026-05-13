{% test parseable_date(model, column_name) %}
  {# Failing rows: non-null raw values that do not cast to DATE (DuckDB). Use on sources or
     pre-staging relations — not on models that already try_cast invalids to NULL. #}
  select *
  from {{ model }}
  where {{ column_name }} is not null
    and try_cast(cast({{ column_name }} as varchar) as date) is null
{% endtest %}
