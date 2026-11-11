-- Analysis: compiles to SQL but does NOT create a database object.
-- Useful for ad-hoc queries, data exploration, or sharing SQL with analysts.
-- Run `dbt compile` to see the compiled SQL in target/compiled/

-- Find customers with more than one order and their average spend
select
    customer_name,
    total_orders,
    total_spent,
    (total_spent / total_orders) as avg_order_value
from {{ ref('customer_orders') }}
where total_orders > 1
order by total_spent desc
