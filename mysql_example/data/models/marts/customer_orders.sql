-- Aggregates order data per customer.
-- Demonstrates: table materialization, ref() to an ephemeral model, aggregation.

{{ config(materialized='table') }}

select
    customer_name,
    count(*) as total_orders,
    sum(amount_dollars) as total_spent,
    min(created_at) as first_order_at,
    max(created_at) as last_order_at
from {{ ref('stg_orders') }}
group by customer_name
