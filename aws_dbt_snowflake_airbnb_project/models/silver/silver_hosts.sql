{{ config(materialized='incremental',
      unique_key='HOST_ID',
      incremental_strategy='merge',
        on_schema_change='append_new_columns') }}

select
    host_id,
    {{trimmer('host_name')}} as host_full_name,
    {{ dbt.split_part(string_text='host_name', delimiter_text="' '", part_number=1) }} as host_first_name,
    {{ dbt.split_part(string_text='host_name', delimiter_text="' '", part_number=2) }} as host_last_name,
    Host_since,
    Is_superhost,
    response_rate,
    {{tag('response_rate')}} as response_rate_flag,
    current_timestamp() as snowflake_load_time
from
    {{ref('bronze_hosts')}}