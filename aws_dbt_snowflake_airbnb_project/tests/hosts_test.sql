select
    host_id,
    count(1) as cnt_total
from
    {{ref('silver_hosts')}}
group by
    1
having cnt_total > 1