with products as (
    select * from {{ ref('stg_products') }}
),

items as (
    select
        product_id,
        count(order_id)     as total_orders,
        sum(price)          as total_revenue,
        avg(price)          as avg_price
    from {{ ref('stg_order_items') }}
    group by product_id
),

final as (
    select
        p.product_id,
        p.product_category_name_english as category,
        p.product_weight_g,
        i.total_orders,
        i.total_revenue,
        i.avg_price
    from products p
    left join items i on p.product_id = i.product_id
)

select * from final