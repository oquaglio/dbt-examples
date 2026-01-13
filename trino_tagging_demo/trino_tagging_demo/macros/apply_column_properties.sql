-- Enhanced macro to apply column properties (optional but very Snowflake-like)
{% macro apply_column_properties() %}
  {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "model") %}
    {% if node.columns %}
      {% for col_name, col in node.columns.items() %}
        {% if col.meta.trino_properties is defined %}
          {% set props = col.meta.trino_properties %}
          {% for key, value in props.items() %}
            {% set sql %}
              ALTER TABLE {{ node.schema }}.{{ node.name }}
              CHANGE COLUMN {{ col_name }}
              SET PROPERTIES {{ key }} = '{{ value }}'
            {% endset %}
            {{ log("Applying column property " ~ key ~ "=" ~ value ~ " on " ~ col_name) }}
            {{ run_query(sql) }}
          {% endfor %}
        {% endif %}
      {% endfor %}
    {% endif %}
  {% endfor %}
{% endmacro %}
