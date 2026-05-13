{% test valid_price(model, column_name) %}
  {# Failing rows: null raw values  Use on sources or
     pre-staging relations — not on models that forward the null. #}
  select *
  from {{ model }}
  where {{ column_name }} is null
{% endtest %}
