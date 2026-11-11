-- Singular test: a standalone SQL query that fails if it returns any rows.
-- This test checks that every customer in orders_incremental also appears
-- in customer_orders (i.e., no orphaned orders without a customer summary).

select oi.customer_name
from {{ ref('orders_incremental') }} oi
left join {{ ref('customer_orders') }} co
    on oi.customer_name = co.customer_name
where co.customer_name is null
