{%- macro multiply(x, y, precision) -%}
    round({{ x }} * {{ y }}, {{ precision | default(2) }})
{%- endmacro -%}