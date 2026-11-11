-- Incremental model: only processes new/updated rows on subsequent runs.
-- On first run, the full dataset is loaded. On subsequent runs, only rows
-- where updated_at is newer than the latest existing row are processed.
-- Uses dbt_utils.generate_surrogate_key (from packages.yml) for a hashed order key.

{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

select
    order_id,
    customer_name,
    status,
    amount_dollars,
    {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_key,
    created_at,
    updated_at
from {{ ref('stg_orders') }}

{% if is_incremental() %}
    -- On incremental runs, only load rows updated since the last run
    where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
