{{ config(materialized='incremental',
      unique_key='LISTING_ID',
      incremental_strategy='merge',
        on_schema_change='append_new_columns') }}

select listing_id,
        host_id,
        {{trimmer('property_type')}} as property_type,
        {{trimmer('room_type')}} as room_type,
        {{trimmer('city')}} as city,
        {{trimmer('country')}} as country,
        ACCOMMODATES,
        bedrooms,
        bathrooms,
        price_per_night,
        {{tag('price_per_night')}} as price_flag,
        {{add('bedrooms','bathrooms')}} as total_rooms,
        current_timestamp() as snowflake_load_time
from {{ ref('bronze_listings') }}