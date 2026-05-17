with source as (
    select * from {{ source('olist', 'PRODUCTS_DATASET') }}
),

category as (
    select * from {{ source('olist', 'PRODUCT_CATEGORY_NAME') }}
),

renamed as (
    select
        s.product_id,
        s.product_category_name,
        c.product_category_name_english,
        s.product_weight_g::float   as product_weight_g,
        s.product_length_cm::float  as product_length_cm,
        s.product_height_cm::float  as product_height_cm,
        s.product_width_cm::float   as product_width_cm,
        s.product_photos_qty::int   as product_photos_qty
    from source s
    left join category c
        on s.product_category_name = c.product_category_name
)

select * from renamed