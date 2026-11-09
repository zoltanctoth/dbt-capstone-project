with src_airports as (
    select * from {{ ref('src_airports') }}
)

select * from src_airports