create or replace view airline_statistic as
select
    a.op_carrier_airline_id,
    count(*) as cnt_flight,
    round(avg(f.dep_delay), 2) as avg_dep_delay,
    round(avg(f.arr_delay), 2) as avg_arr_delay,
    count(*) filter(where f.cancelled) as cncl_flight,
    ROUND(100.0 * COUNT(*) FILTER (WHERE f.cancelled) / COUNT(*), 2) AS share_cncl_flight
from flight as f
join airline as a
on f.airline_id = a.airline_id
group by 1
order by 2 desc