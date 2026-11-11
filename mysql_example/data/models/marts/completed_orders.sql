-- Filters to only completed orders.
-- Demonstrates: view materialization (set in config() below, overriding the marts/
-- default of incremental from dbt_project.yml), ref() chaining.

{{ config(materialized='view') }}

select
    order_id,
    customer_name,
    amount_dollars,
    created_at
from {{ ref('stg_orders') }}
where status = 'completed'
