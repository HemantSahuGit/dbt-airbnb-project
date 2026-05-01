{{ config(materialized='incremental',
      unique_key='BOOKING_ID',
      incremental_strategy='merge',
        on_schema_change='append_new_columns') }}

select LISTING_ID,
        Booking_id,
        BOOKING_DATE,
        {{ multiply('NIGHTS_BOOKED', 'BOOKING_AMOUNT') }} as ROOM_RENT_AMOUNT,
        ROOM_RENT_AMOUNT + cleaning_fee + service_fee as total_amount,
        Booking_status,
        current_timestamp() as snowflake_load_time
from {{ ref('bronze_bookings') }}