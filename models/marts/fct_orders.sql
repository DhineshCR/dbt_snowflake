with orders as (
    select * from {{ ref('stg_orders') }}
),

items as (
    select
        order_id,
        count(order_item_id)        as total_items,
        sum(price)                  as total_price,
        sum(freight_value)          as total_freight
    from {{ ref('stg_order_items') }}
    group by order_id
),

payments as (
    select
        order_id,
        sum(payment_value)          as total_payment,
        count(payment_sequential)   as payment_count
    from {{ ref('stg_order_payments') }}
    group by order_id
),

reviews as (
    select
        order_id,
        review_score
    from {{ ref('stg_order_reviews') }}
),

final as (
    select
        o.order_id,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        datediff('day',
            o.order_purchase_timestamp,
            o.order_delivered_customer_date)    as actual_delivery_days,
        datediff('day',
            o.order_purchase_timestamp,
            o.order_estimated_delivery_date)    as estimated_delivery_days,
        i.total_items,
        i.total_price,
        i.total_freight,
        p.total_payment,
        p.payment_count,
        r.review_score
    from orders o
    left join items i      on o.order_id = i.order_id
    left join payments p   on o.order_id = p.order_id
    left join reviews r    on o.order_id = r.order_id
)

select * from final