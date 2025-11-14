{{ config(materialized='table') }}

SELECT 1 AS id, 'hello' AS message
UNION
SELECT 2 AS id, 'world' AS message
