{{
    config(materialized= 'ephemeral')
}}


with
booking_dim as (
    select
        distinct booking_id,
        listing_id,
        booking_date,
        booking_status,
        created_at as booking_created_date
        from {{ ref('obt') }}
) select * from booking_dim