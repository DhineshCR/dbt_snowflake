with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select
        customer_id,
        count(order_id)         as total_orders,
        sum(total_payment)      as lifetime_value,
        avg(review_score)       as avg_review_score,
        min(order_purchase_timestamp) as first_order_date,
        max(order_purchase_timestamp) as last_order_date
    from {{ ref('fct_orders') }}
    group by customer_id
),

final as (
    select
        c.customer_id,
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        o.total_orders,
        o.lifetime_value,
        o.avg_review_score,
        o.first_order_date,
        o.last_order_date
    from customers c
    left join orders o on c.customer_id = o.customer_id
)

select * from final