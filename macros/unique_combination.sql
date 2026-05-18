-- Generic test: A list of columns should together form a unique key.
-- Usage in schema.yml:
--   tests:
--     - unique_combination:
--         columns: [country, year_month]

{% test unique_combination(model, columns) %}

select
    {{ columns | join(', ') }},
    count(*) as duplicate_count
from {{ model }}
group by {{ columns | join(', ') }}
having count(*) > 1

{% endtest %}
