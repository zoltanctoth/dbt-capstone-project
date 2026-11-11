with comments as (
    select * from {{ ref('silver_airport_comments') }}
)

select
    comment_id,
    comment_timestamp
from comments
where comment_timestamp > current_timestamp()