--- setup datastore
CREATE extension tablefunc;

drop table if exists instructions;

create table instructions (
    count SERIAL,
    instruction TEXT,
    size integer
);

--- prod data
copy instructions (instruction, size)
from
    '/workspace/02/input.txt' DELIMITER ' ';

--- measurement part 1
with totals as (
    select
        *
    from
        crosstab(
            'select
        instruction,
        sum(size)
    from
        instructions
    group by
        instruction
    order by 1,2'
        )
)
select
    *
from
    totals
from
    totals;

/*
 instruction | sum
 -------------+------
 forward     | 1832
 down        | 2205
 up          | 1033
 (3 rows)

 1832 * 2205-1033 = 2147104
 */
--- part 2
/*
 down X increases your aim by X units.
 up X decreases your aim by X units.
 forward X does two things:
 It increases your horizontal position by X units.
 It increases your depth by your aim multiplied by X.
 */
with calc_totals as (
    with running_totals as (
        with totals as (
            select
                instructions.count as count,
                max(instructions.instruction) as instruction,
                max(instructions.size) as size,
                i2.instruction as prev_instruction,
                sum(i2.size) as sum_prev_instruction
            from
                instructions
                join instructions i2 on i2.count < instructions.count
            group by
                instructions.count,
                i2.instruction
        )
        select
            count,
            max(instruction) as instruction,
            max(size) as size,
            sum(
                CASE
                    WHEN prev_instruction = 'up' THEN sum_prev_instruction
                    ELSE 0
                END
            ) as prev_up,
            sum(
                CASE
                    WHEN prev_instruction = 'down' THEN sum_prev_instruction
                    ELSE 0
                END
            ) as prev_down,
            sum(
                CASE
                    WHEN prev_instruction = 'forward' THEN sum_prev_instruction
                    ELSE 0
                END
            ) as prev_forward
        from
            totals
        group by
            count
    )
    select
        *,
        (prev_down - prev_up) as prev_aim,
        case
            when instruction = 'forward' then (prev_down - prev_up) * size
            else 0
        end as forward_offset
    from
        running_totals
)
select
    *
from
    calc_totals;