{{ config(materialized='incremental',
      unique_key='BOOKING_ID',
      incremental_strategy='merge',
        on_schema_change='append_new_columns') }}

select *,
        current_timestamp() as snowflake_load_time
from {{ source('staging', 'bookings') }}

{% if is_incremental() %}
where CREATED_AT >= (
    select coalesce(max(CREATED_AT), cast('1900-01-01' as timestamp))
    from {{ this }}
)
{% endif %}