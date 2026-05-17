-- Fails if any order item price is zero or negative
SELECT *
FROM {{ ref('stg_order_items') }}
WHERE price <= 0