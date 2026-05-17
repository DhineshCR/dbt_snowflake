-- Fails if review score is outside 1-5
SELECT *
FROM {{ ref('stg_order_reviews') }}
WHERE review_score NOT IN (1, 2, 3, 4, 5)