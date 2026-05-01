{% macro tag(column) %}
    case
        when {{column}} is null then 'Null'
        when {{column}}::int < 100 then 'Low'
        when {{column}}::int < 200 then 'Medium'
        else 'High'
    end 
{% endmacro %}