{% set cols = ['nights_booked', 'booking_date', 'booking_amount']%}

select
    {% for col in cols %}
    {{ col }} {% if not loop.last %}, {% endif %}
    {% endfor %}
from
    {{ ref('bronze_bookings') }}