-- Ephemeral model: compiles to a CTE, no database object is created.
-- This is useful for lightweight transformations that don't need their own table/view.

{{ config(materialized='ephemeral') }}

select
    order_id,
    customer_name,
    status,
    {{ cents_to_dollars('amount_cents') }} as amount_dollars,
    created_at,
    updated_at
from {{ source('raw', 'raw_orders') }}
