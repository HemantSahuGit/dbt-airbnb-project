{%
    set configs = [
    {
        "table" : "airbnb.bronze.bronze_bookings",
        "columns" : "bronze_bookings.*",
        "alias" : "bronze_bookings"
    },
    {
        "table" : "airbnb.bronze.bronze_listings",
        "columns" : " bronze_listings.host_id, bronze_listings.property_type, bronze_listings.room_type, bronze_listings.city, bronze_listings.country, bronze_listings.accommodates, bronze_listings.bedrooms, bronze_listings.bathrooms, bronze_listings.price_per_night",
        "alias" : "bronze_listings",
        "join_condition": "bronze_bookings.listing_id = bronze_listings.listing_id"
    },
    {
        "table" : "airbnb.bronze.bronze_hosts",
        "columns" : " bronze_hosts.host_name, bronze_hosts.host_since, bronze_hosts.is_superhost, bronze_hosts.response_rate ",
        "alias" : "bronze_hosts",
        "join_condition": "bronze_listings.host_id = bronze_hosts.host_id"
    }
    ]
%}

select
    {% for config in configs %}
        {{config.columns}} {% if not loop.last %} , {% endif%}
    {% endfor%}
from
    {% for config in configs%}
        {% if loop.first%}
            {{config.table}} as {{config.alias}}
        {%else%}
            left join {{config.table}} as {{config.alias}} on {{config.join_condition}}
        {% endif%}
    {% endfor %}
