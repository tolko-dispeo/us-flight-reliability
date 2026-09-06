create or replace view v_flight_details as
select
    f.flight_id,
    f.fl_date as flight_date,
    a.op_carrier_airline_id as op_carrier_airline_id,
    f.op_carrier_fl_num as op_carrier_fl_num,
    ac.tail_num as tail_num,

    origin.airport_id as origin_airport_id,
    origin.city_name as origin_city,
    origin.state_abr as origin_state,

    dest.airport_id as dest_airport_id,
    dest.city_name as dest_city,
    dest.state_abr as dest_state,

    f.crs_dep_time as crs_dep_time,
    f.dep_time as dep_time,
    f.dep_delay as dep_delay,

    f.crs_arr_time as crs_arr_time,
    f.arr_time as arr_time,
    f.arr_delay as arr_delay,

    f.cancelled as cancelled,
    f.diverted as diverted,
    f.distance as distance
from flight as f
join airline as a
on f.airline_id = a.airline_id
join airport as origin
on f.origin_airport_id = origin.airport_id
join airport as dest
on f.dest_airport_id = dest.airport_id
left join aircraft as ac
on f.aircraft_id = ac.aircraft_id;
