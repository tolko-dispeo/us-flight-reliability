
select count(*) as all_flight
from flight;
-- выведет общее число рейсов в базе данных

select
    count(*) filter(where cancelled) as cncl_fligths,
    round( (100.0 * count(*) filter(where cancelled)) / count(*), 2) as share_cancelled_flights
from flight
-- доля отмененных рейсов

select
    round(avg(dep_delay), 2) as avg_dep_delay,
    round(avg(arr_delay), 2) as avg_arr_delay
from flight
-- среднии задержки вылета и прилета общие

select
    a.airport_id,
    a.city_name,
    a.state_abr,
    round(avg(dep_delay), 2) as avg_dep_delay,
    round(avg(arr_delay), 2) as avg_arr_delay
from flight as f
join airport as a
on f.origin_airport_id = a.airport_id
group by 1, 2, 3
order by 4 desc;
-- задержки считаются по тем аэропортам из которых вылетели,
-- аналогично можно посчитать для тех куда прилетели

select
    a.airport_id,
    a.city_name,
    a.state_abr,
    count(*) as cnt_flight
from flight as f
join airport as a
on f.origin_airport_id = a.airport_id
group by 1, 2, 3
order by 4 desc
limit 10;
-- топ 10 аэропорты по загруженности вылетов

select
    a.airport_id,
    a.city_name,
    a.state_abr,
    count(*) as cnt_flight
from flight as f
join airport as a
ON f.dest_airport_id = a.airport_id
group by 1, 2, 3
order by 4 desc
limit 10;
-- топ 10 аэропорты по загруженности прилетов

select
    origin.city_name as origin_city,
    dest.city_name as dest_city,
    count(*) as cnt_flight
from flight as f
join airport as origin
on f.origin_airport_id = origin.airport_id
join airport dest
on f.origin_airport_id = dest.airport_id
group by
    origin.airport_id,
    origin.city_name,
    dest.airport_id,
    dest.city_name
order by 3 desc
limit 10;
-- топ 10 маршрутов по количеству

select
    a.op_carrier_airline_id,
    count(*) as cnt_flight,
    round(avg(f.dep_delay), 2) as avg_dep_delay,
    round(avg(f.arr_delay), 2) as avg_arr_delay
from flight as f
join airline as a
on f.airline_id = a.airline_id
group by 1
order by 2 desc
-- статистика авиакомпаний по количеству рейсов и средних задержек

select
    a.op_carrier_airline_id,
    count(*) as cnt_flight,
    count(*) filter (where f.cancelled) as cncl_fligths,
    round(100.0 * (count(*) filter (where f.cancelled)) / count(*), 2) as share_cancelled_flights_airline
from flight as f
join airline as a
on f.airline_id = a.airline_id
group by 1
order by 4 desc
-- тут получаем долю отмененных рейсов для каждой компании

select
    fl_date as flight_date,
    count(*) as cnt_flight
from flight
group by 1
order by 1
-- количество рейсов в каждом дне

select
    f.flight_id,
    f.fl_date as flight_date
    origin.city_name AS origin_city,
    dest.city_name AS dest_city,
    f.distance as distance
from flight as f
join airport as origin
on f.origin_airport_id = origin.airport_id
join airport dest
on f.dest_airport_id = dest.airport_id
order by 5 desc
limit 10;
-- топ 10 самых длинных рейсов по расстоянию

select
    a.tail_num as number_tail,
    count(*) as cnt_flight
from flight as f
join aircraft as a
on f.aircraft_id = a.tail_num
order by 1 desc
limit 10;
-- топ 10 самых используемых самолетов

select
    dr.code,
    count(*) as cnt_delay,
    sum(fd.delay_minutes) as all_delay_min,
    round(avg(fd.delay_minutes), 2) as avg_delay_min
from flight_delay as fd
join delay_reason as dr
on fd.delay_reason_id = dr.delay_reason_id
group by 1
order by 3 desc;
-- по каждому виду задержке указали количество и суммарное время и среднее время

select
    flight_id,
    count(*) as cnt_reason,
    sum(delay_minutes) as sum_delay_min
from flight_delay
group by 1
having(count(*)) >= 2
order by 2 desc, 3 desc
limit 15
-- рейсы у которых 2 и более причин задержек

with statistic_route as (
    select
        origin_airport_id,
        dest_airport_id,
        count(*) as cnt_flight
    from flight
    group by 1, 2
),
stat_route_rank as (
    select
        *,
        row_number() over(partition by origin_airport_id order by cnt_flight desc) as rank_route
    from statistic_route
)
select
    origin.city_name as origin_city,
    dest.city_name as dest_city,
    srr.cnt_flight as cnt_flight,
    srr.rank_route as rank_route
from stat_route_rank as srr
join airport origin
on srr.origin_airport_id = origin.airport_id
join airport dest
on srr.dest_airport_id = dest.airport_id
where srr.rank_route <= 3
order by 1, 4

-- топ 3 популярных направления для каждого аэропорта отправления

select
    a.airport_id as airport_id,
    a.city_name as city_name,
    a.state_abr as state
from airport as a
where exists (
    select 1
    from flight as f
    where f.origin_airport_id = a.airport_id and f.cancelled = TRUE
)
order by 2
-- Аэропорты где хотя бы 1 раз отменили рейс