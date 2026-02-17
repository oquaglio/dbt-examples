-- Filters to only completed orders.
-- Demonstrates: view materialization (inherited from dbt_project.yml), ref() chaining.

{{ config(materialized='view') }}

select
    order_id,
    customer_name,
    amount_dollars,
    created_at
from {{ ref('stg_orders') }}
where status = 'completed'
