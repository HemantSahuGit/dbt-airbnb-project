{% macro trimmer(column)%}
    upper(trim({{column}}))
{% endmacro%}