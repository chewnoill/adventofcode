create schema if not exists aoc2022_day3;

drop table if exists aoc2022_day3.input cascade;

create table aoc2022_day3.input (row SERIAL, value text);

copy aoc2022_day3.input (value)
from
    '/workspace/03/input.txt' DELIMITER ' ';

create
or replace view aoc2022_day3.input_set as (
    SELECT
        row,
        v as value,
        ordinality as column_number
    from
        aoc2022_day3.input,
        unnest(string_to_array(value, null)) WITH ORDINALITY AS v
);

create view aoc2022_day3.most_common as (
    select
        column_number,
        mode() within group (
            order by
                value
        ) as most_common
    from
        aoc2022_day3.input_set
    group by
        column_number
);

create or replace function bit_to_int (value text)
RETURNS int
LANGUAGE sql STRICT
AS $$ 
select lpad(value, 32, '0') :: bit(32) :: int;
$$;

create or replace function aoc2022_day3.colX (the_column_number integer) 
RETURNS SETOF aoc2022_day3.input_set 
LANGUAGE sql STRICT
AS $$ 
 	select
        aoc2022_day3.input_set.*
    from
        aoc2022_day3.input_set
        join aoc2022_day3.most_common using(column_number)
    where
        column_number = the_column_number
        and value = most_common;
$$;

WITH RECURSIVE colX(n) AS (
    VALUES (1)
  UNION ALL
    SELECT n+1 FROM t WHERE n < 100
);

select
    *
from aoc2022_day3.input
join aoc2022_day3.colX(1) as col1 using(row)
join aoc2022_day3.colX(2) as col2 using(row)
join aoc2022_day3.colX(3) as col3 using(row)
join aoc2022_day3.colX(4) as col4 using(row)
join aoc2022_day3.colX(5) as col5 using(row);

WITH RECURSIVE colX(prefix, col, ) AS (
    SELECT sub_part, part FROM parts WHERE part = 'our_product'
  UNION ALL
    SELECT p.sub_part, p.part
    FROM included_parts pr, parts p
    WHERE p.part = pr.sub_part
)
DELETE FROM parts
  WHERE part IN (SELECT part FROM included_parts);

select
    *
from
    aoc2022_day3.input_set;

with input_set as (
    SELECT
        row,
        v as value,
        ordinality as column_number
    from
        aoc2022_day3.input,
        unnest(string_to_array(value, null)) WITH ORDINALITY AS v
),
most_common as (
    select
        column_number,
        mode() within group (
            order by
                value
        ) as most_common
    from
        input_set
    group by
        column_number
),
common as (
    select
        column_number,
        most_common,
        case
            when most_common = '0' then '1'
            else '0'
        end least_common
    from
        most_common
),
rates as (
    SELECT
        string_agg(most_common, '') over () gamma,
        string_agg(least_common, '') over () epsilon
    from
        common
    limit
        1
)
select
    lpad(gamma, 32, '0') :: bit(32) :: int * lpad(epsilon, 32, '0') :: bit(32) :: int as result
from
    rates;

/**
 * Input Set:
 *
 */
with input_set as (
    SELECT
        count as row,
        v as value,
        ordinality as column_number
    from
        aoc2022_day3.input,
        unnest(string_to_array(value, null)) WITH ORDINALITY AS v
),
most_common as (
    select
        column_number,
        mode() within group (
            order by
                value
        ) as most_common
    from
        input_set
    group by
        column_number
),
common as (
    select
        column_number,
        most_common,
        case
            when most_common = '0' then '1'
            else '0'
        end least_common
    from
        most_common
)
select
    row,
    count(column_number)
from
    input_set
    join common using(column_number)
where
    most_common = value
group by
    row;

WITH RECURSIVE input_set_with_prefix AS (
	SELECT
		input_set.row,
		input_set.column_number,
		input_set.value,
		STRING_AGG(prefix.value,
			'' ORDER BY prefix.column_number) AS prefix
	FROM
		aoc2022_day3.input_set
	LEFT JOIN aoc2022_day3.input_set AS prefix ON input_set.row = prefix.row
		AND prefix.column_number < input_set.column_number
	GROUP BY
		input_set.row,
		input_set.column_number,
		input_set.value
	ORDER BY
		input_set.row,
		input_set.column_number
),
input_chain AS (
	SELECT
		input_set_with_prefix.value,
		column_number,
		ROW,
		prefix,
		COALESCE(prefix,
			'') || value AS value_agg
	FROM
		input_set_with_prefix
WHERE
	prefix IS NULL
UNION
SELECT
	input.value,
	input.column_number,
	input.row,
	input.prefix,
	COALESCE(input.prefix,
		'') || input.value
FROM
	input_chain
	JOIN input_set_with_prefix input ON input_chain.value_agg = input.prefix
),
counted_results AS (
	SELECT
		column_number,
		value,
		count(*),
		coalesce(prefix,
			'') AS prefix
	FROM
		input_chain
	GROUP BY
		column_number,
		prefix,
		value
	ORDER BY
		column_number
),
o2_level AS (
SELECT
	mc.column_number,
	mc.value,
	mc.count,
	mc.prefix
FROM
	counted_results mc
	JOIN counted_results mc2 ON mc.column_number = mc2.column_number
		AND mc.value != mc2.value
		and(mc.count > mc2.count
		or(mc.count = mc2.count
		AND mc.value = '1'))
		AND mc.column_number = 1
	GROUP BY
		mc.column_number,
		mc.value,
		mc.count,
		mc.prefix
UNION
SELECT
	mc.column_number,
	mc.value,
	mc.count,
	mc.prefix
FROM
	counted_results mc
	JOIN counted_results mc2 ON mc.prefix = mc2.prefix
		AND mc.value != mc2.value
		and(mc.count > mc2.count
		or(mc.count = mc2.count
		AND mc.value = '1'))
	JOIN o2_level on coalesce(o2_level.prefix, '') || o2_level.value = mc.prefix
),
co2_level AS (
SELECT
	mc.column_number,
	mc.value,
	mc.count,
	mc.prefix
FROM
	counted_results mc
	JOIN counted_results mc2 ON mc.column_number = mc2.column_number
		AND mc.value != mc2.value
		and(mc.count < mc2.count
		or(mc.count = mc2.count
		AND mc.value = '0'))
		AND mc.column_number = 1
	GROUP BY
		mc.column_number,
		mc.value,
		mc.count,
		mc.prefix
UNION
SELECT
	mc.column_number,
	mc.value,
	mc.count,
	mc.prefix
FROM
	counted_results mc
	JOIN counted_results mc2 ON mc.prefix = mc2.prefix
		AND mc.value != mc2.value
		and(mc.count < mc2.count
		or(mc.count = mc2.count
		AND mc.value = '0'))
	JOIN co2_level on coalesce(co2_level.prefix, '') || co2_level.value = mc.prefix
)
select 
*,  bit_to_int(input.value)
from input_set_with_prefix input_set
join aoc2022_day3.input using(row)
where (prefix || input_set.value) = (SELECT string_agg(value,'' order by column_number) FROM o2_level)
or (prefix || input_set.value) = (SELECT string_agg(value,'' order by column_number) FROM co2_level)


	;

WITH RECURSIVE input_set_with_prefix AS (
	SELECT
		input_set.row,
		input_set.column_number,
		input_set.value,
		STRING_AGG(prefix.value,
			'' ORDER BY prefix.column_number) AS prefix
	FROM
		aoc2022_day3.input_set
	LEFT JOIN aoc2022_day3.input_set AS prefix ON input_set.row = prefix.row
		AND prefix.column_number < input_set.column_number
	GROUP BY
		input_set.row,
		input_set.column_number,
		input_set.value
	ORDER BY
		input_set.row,
		input_set.column_number
),
input_chain AS (
	SELECT
		input_set_with_prefix.value,
		column_number,
		ROW,
		prefix,
		COALESCE(prefix,
			'') || value AS value_agg
	FROM
		input_set_with_prefix
WHERE
	prefix IS NULL
UNION ALL
SELECT
	input.value,
	input.column_number,
	input.row,
	input.prefix,
	COALESCE(input.prefix,
		'') || input.value
FROM
	input_chain
	JOIN input_set_with_prefix input ON input_chain.value_agg = input.prefix
),
most_common AS (
	SELECT
		column_number,
		value,
		count(*),
		coalesce(prefix,
			'') || value AS prefix
	FROM
		input_chain
	WHERE
		column_number = 1
	GROUP BY
		column_number,
		prefix,
		value
	UNION ALL
	SELECT
		input_chain.column_number,
		input_chain.value,
		count(*) OVER (PARTITION BY input_chain.column_number,
			input_chain.prefix,
			input_chain.value),
		input_chain.prefix || input_chain.value
	FROM
		input_chain
		JOIN most_common USING (prefix)
	GROUP BY
		input_chain.column_number,
		input_chain.prefix,
		input_chain.value
),
result_please AS (
SELECT
	mc.column_number,
	mc.value,
	mc.count,
	mc.prefix
FROM
	most_common mc
	JOIN most_common mc2 ON mc.column_number = mc2.column_number
		AND mc.value != mc2.value
		and(mc.count > mc2.count
		or(mc.count = mc2.count
		AND mc.value = '1'))
		AND mc.column_number = 1
	GROUP BY
		mc.column_number,
		mc.value,
		mc.count,
		mc.prefix
	UNION ALL
	SELECT
		mc.column_number,
		mc.value,
		mc.count,
		mc.prefix
	FROM
		most_common mc
	JOIN result_please ON result_please.prefix || mc.value = mc.prefix
	JOIN most_common mc2 ON mc.column_number = mc2.column_number
		AND mc.value != mc2.value
		and(mc.count > mc2.count
			or ( mc.count = mc2.count
			AND mc.value = '1'))
	
		GROUP BY
		mc.column_number,
		mc.value,
		mc.count,
		mc.prefix
)
SELECT
	*
FROM
	result_please