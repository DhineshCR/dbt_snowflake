{% snapshot snp_orders %}

{{
    config(
        target_schema='snapshots',
        unique_key='order_id',
        strategy='check',
        check_cols=['order_status',
                    'order_delivered_customer_date',
                    'order_approved_at']
    )
}}

SELECT * FROM {{ source('olist', 'ORDERS_DATASET') }}

{% endsnapshot %}