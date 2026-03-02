-- Generic test: Column should be positive (> 0)
-- Usage: {{ test_positive_amount(column_name='total_amount') }}

{% test positive_amount(model, column_name) %}

select
    {{ column_name }}
from {{ model }}
where {{ column_name }} <= 0 or {{ column_name }} is null

{% endtest %}
