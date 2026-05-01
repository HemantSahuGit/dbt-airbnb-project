{% macro add(col1, col2) %}
    {{col1}}::int + {{col2}}::int
{% endmacro %}