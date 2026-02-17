-- Snapshot: implements SCD Type 2 (Slowly Changing Dimension).
-- Tracks historical changes to raw_orders over time.
-- Each time a row's `updated_at` changes, a new version is recorded
-- with dbt_valid_from / dbt_valid_to columns.

{% snapshot orders_snapshot %}

{{
    config(
        target_schema='dbt_example',
        unique_key='order_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select * from {{ source('raw', 'raw_orders') }}

{% endsnapshot %}
