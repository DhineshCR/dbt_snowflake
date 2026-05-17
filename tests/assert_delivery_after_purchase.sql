-- Fails if delivery date is before purchase date
SELECT *
FROM {{ ref('fct_orders') }}
WHERE order_delivered_customer_date < order_purchase_timestamp