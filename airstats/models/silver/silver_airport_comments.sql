{{ config(materialized='incremental') }}

with src as (
    select * from {{ ref('src_airport_comments') }}
)

select
    comment_id,
    airport_ident,
    comment_timestamp,
    NVL(member_nickname, '__UNKNOWN__') as member_nickname,
    comment_subject,
    comment_body,
    current_timestamp() as loaded_at
from src
where comment_body is not null
and comment_body != ''

{% if is_incremental() %}
  and comment_id > (select max(comment_id) from {{ this }})
{% endif %}