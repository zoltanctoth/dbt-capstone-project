{{ config(severity='warn') }}

with airports as (
    select * from {{ ref('silver_airports') }}
),

runways as (
    select * from {{ ref('silver_runways') }}
)

select
    r.runway_id,
    r.airport_ident
from runways r
join airports a
    on r.airport_ident = a.airport_ident
where a.airport_type = 'closed'
  and r.runway_closed = 0