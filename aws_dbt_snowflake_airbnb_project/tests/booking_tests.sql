select
    booking_id,
    count(*) as cnt_total
from
    {{ref("silver_bookings")}}
group by
    1
having cnt_total > 1