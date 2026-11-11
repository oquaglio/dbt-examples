{{ config(materialized='table') }}

SELECT * FROM {{ ref('sample_data') }}
