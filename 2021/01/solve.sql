--- setup datastore
drop table if exists measurements;

create table measurements (count SERIAL, depth integer);

--- test data
insert into
    measurements (depth)
values
    (199),
    (200),
    (208),
    (210),
    (200),
    (207),
    (240),
    (269),
    (260),
    (263);

--- prod data
copy measurements (depth)
from
    '/workspace/01/input.txt';

--- measurement part 1
with depth_readings as (
    select
        depth,
        lag(depth) over(
            order by
                count
        ) as prev_depth
    from
        measurements
)
select
    count(*)
from
    depth_readings
where
    (depth > prev_depth);

--- measurement part 2
with rolling_depth_readings as (
    with depth_readings as (
        select
            count,
            depth,
            lag(depth) over(
                order by
                    count
            ) as prev_depth,
            lead(depth) over(
                order by
                    count
            ) as next_depth
        from
            measurements
    )
    select
        prev_depth,
        next_depth,
        lag(depth + prev_depth + next_depth) over(
            order by
                count
        ) as prev_total,
        depth + prev_depth + next_depth as current_total
    from
        depth_readings
)
select
    count(*)
from
    rolling_depth_readings
where
    current_total > prev_total
    and prev_depth is not null
    and next_depth is not null;