-- Level 1 — Aggregations & Grouping
-- Q1. Total revenue and order count by month

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS order_month,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(total_payment), 2) AS total_revenue
FROM
    fct_orders
WHERE
    order_status = 'delivered'
GROUP BY
    1
ORDER BY
    1;

-- Q2. Top 10 states by number of orders

SELECT
    c.customer_state,
    COUNT(o.order_id) AS total_orders
FROM
    fct_orders o
    JOIN dim_customers c ON o.customer_id = c.customer_id
GROUP BY
    1
ORDER BY
    2 DESC
LIMIT
    10;

-- Q3. Average review score by order status

select
    order_status,
    round(avg(review_score), 2) as average_review_score
from
    fct_orders
group by
    1
order by
    2 desc;

-- Level 2 — CTEs & Joins
-- Q4. Orders that were delivered late

with base as (
SELECT
    order_id,
    COUNT(order_id) as total_orders,
    customer_id,
    order_status,
    actual_delivery_days,
    estimated_delivery_days,
    actual_delivery_days - estimated_delivery_days AS delay_days
FROM
    fct_orders
WHERE
    order_status = 'delivered'
    AND actual_delivery_days IS NOT NULL
group by 1,3,4,5,6,7
)
SELECT
    COUNT(order_id) as late_orders,
    ROUND(AVG(delay_days), 2) as avg_delay_days,
    ROUND(
        COUNT(order_id) * 100.0 /(
            select
                COUNT(order_id)
            from
                base
        ),
        2
    ) as pct_late_orders
FROM
    base
where
    delay_days > 0;

-- Top 5 product categories by revenue

WITH BASE AS (
    SELECT
        CATEGORY,
        ROUND(SUM(TOTAL_REVENUE), 1) AS TOTAL_REVENUE
    FROM
        DIM_PRODUCTS
    WHERE
        CATEGORY IS NOT NULL
    GROUP BY
        1
    ORDER BY
        2 DESC
)
SELECT
    REPLACE(INITCAP(CATEGORY), '_', ' ') AS CATEGORY,
    CONCAT('$', ROUND(TOTAL_REVENUE / 1000000, 2), 'M') AS TOTAL_REVENUE_M
FROM
    BASE
LIMIT
    5;

-- Q6. Customers who placed more than 1 order

WITH repeat_customers AS (
    SELECT
        customer_unique_id,
        customer_state,
        total_orders,
        ROUND(lifetime_value, 2) AS lifetime_value
    FROM
        dim_customers
    WHERE
        total_orders > 1
)
SELECT
    COUNT(*) AS repeat_customer_count,
    ROUND(AVG(lifetime_value), 2) AS avg_lifetime_value,
    ROUND(AVG(total_orders), 1) AS avg_orders
FROM
    repeat_customers;

-- Level 3 — Window Functions
-- Q7. Rank customers by lifetime value within each state

WITH RANKED_CUSTOMER AS (
    SELECT
        CUSTOMER_ID,
        CUSTOMER_STATE,
        ROUND(LIFETIME_VALUE, 2) AS LIFETIME_VALUE,
        RANK() OVER (
            PARTITION BY CUSTOMER_STATE
            ORDER BY
                LIFETIME_VALUE DESC
        ) AS RANK_IN_STATE
    FROM
        DIM_CUSTOMERS
    WHERE
        lifetime_value IS NOT NULL QUALIFY rank_in_state <= 3
    ORDER BY
        customer_state,
        rank_in_state
    )
SELECT
    *
FROM
    RANKED_CUSTOMER;

-- Q8. Month over month revenue growth

WITH CURRENT_MONTH AS (
    SELECT
        DATE_TRUNC('MONTH', ORDER_PURCHASE_TIMESTAMP) AS MONTH_PURCHASE,
        ROUND(SUM(TOTAL_PAYMENT)) AS CURR_REVENUE
    FROM
        FCT_ORDERS
    WHERE
        order_status = 'delivered'
    GROUP BY
        MONTH_PURCHASE
),
PREV_MONTH AS (
    SELECT
        MONTH_PURCHASE,
        CURR_REVENUE,
        LAG(CURR_REVENUE) OVER (
            ORDER BY
                MONTH_PURCHASE ASC
        ) AS PREV_REVENUE
    FROM
        CURRENT_MONTH
    GROUP BY
        MONTH_PURCHASE,
        CURR_REVENUE
)
SELECT
    MONTH_PURCHASE,
    CURR_REVENUE,
    PREV_REVENUE,
    ROUND(
        (CURR_REVENUE - PREV_REVENUE) * 100.0 / NULLIF(PREV_REVENUE, 0),
        2
    ) AS MOM_GROWTH
FROM
    PREV_MONTH
WHERE
    PREV_REVENUE IS NOT NULL;

-- Q9. Running total revenue over time

WITH MONTHLY AS (
    SELECT
        DATE_TRUNC('month', ORDER_PURCHASE_TIMESTAMP) AS ORDER_MONTH,
        ROUND(SUM(TOTAL_PAYMENT), 2) AS MONTHLY_REVENUE
    FROM
        FCT_ORDERS
    WHERE
        ORDER_STATUS = 'delivered'
    GROUP BY
        1
    )
SELECT
    ORDER_MONTH,
    MONTHLY_REVENUE,
    ROUND(
        SUM(MONTHLY_REVENUE) OVER (
            ORDER BY
                ORDER_MONTH ROWS BETWEEN UNBOUNDED PRECEDING
                AND CURRENT ROW
        ),
        2
    ) AS running_total
FROM
    monthly
ORDER BY
    1;

-- Q10. Top 3 products per category by revenue

SELECT
    CATEGORY,
    PRODUCT_ID,
    TOTAL_REVENUE,
    TOTAL_ORDERS,
    RANK() OVER (
        PARTITION BY CATEGORY
        ORDER BY
            TOTAL_REVENUE DESC
    ) AS PRODUCT_RANKED
FROM
    DIM_PRODUCTS
WHERE
    CATEGORY IS NOT NULL QUALIFY PRODUCT_RANKED <= 3;
