-- Fails if any payment value is negative
SELECT *
FROM {{ ref('stg_order_payments') }}
WHERE payment_value < 0