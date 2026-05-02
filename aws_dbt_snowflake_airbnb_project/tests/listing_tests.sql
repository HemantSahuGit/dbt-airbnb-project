select
    *
from
    {{ref('silver_listings')}}
where price_per_night < 0