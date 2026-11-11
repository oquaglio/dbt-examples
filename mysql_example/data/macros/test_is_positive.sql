-- Custom generic test: reusable across any model/column via schema.yml.
-- Usage in schema.yml:
--   tests:
--     - is_positive
-- Fails if any row has a value <= 0 for the given column.

{% test is_positive(model, column_name) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} <= 0

{% endtest %}
