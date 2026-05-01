{% set flag = 2 %}  {# Default for parsing phase #}

select
    * 
from
    {{ ref('bronze_bookings') }}
where    nights_booked > 
{% if flag > 0 %}
        {{ flag }}
{% else %}
        0
{% endif %}

