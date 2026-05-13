{% test duplicate_key_record(model, column_name) %}
  {# Failing rows: raw value where the select column should only return one record per value. Use on sources or
     pre-staging relations. #}
  select
      test.*
  from (
      select 
          *
          ,count(*) over (partition by {{ column_name }} order by {{ column_name }} rows between unbounded preceding and unbounded following) as count_of_keyvalue
      from {{ model }}
      where {{ column_name }} is not null
  ) test
  WHERE test.count_of_keyvalue > 1    
{% endtest %}
