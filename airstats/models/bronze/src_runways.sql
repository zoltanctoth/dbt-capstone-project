{{ config(materialized='ephemeral') }}

with raw_runways as (
    select * from {{ source('airstats_raw', 'runways') }}
)

select
    id as runway_id,
    airport_ident,
    length_ft as runway_length_ft,
    width_ft as runway_width_ft,
    surface as runway_surface,
    lighted as runway_lighted,
    closed as runway_closed
from raw_runways