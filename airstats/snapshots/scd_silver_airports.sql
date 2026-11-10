{% snapshot scd_silver_airports %}

{{
    config(
        target_schema='snapshots',
        unique_key='airport_ident',
        strategy='check',
        check_cols='all'
    )
}}

select * from {{ ref('silver_airports') }}

{% endsnapshot %}