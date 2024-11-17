/*
 * Remove duplicated values in data column for the table l1.flight_schedules
 * */

CREATE TABLE l1.flight_schedules_tmp (
	total_journey__duration varchar NULL,
	flight__departure__airport_code varchar NULL,
	flight__departure__scheduled_time_local__date_time timestamptz NULL,
	flight__arrival__airport_code varchar NULL,
	flight__arrival__scheduled_time_local__date_time timestamptz NULL,
	flight__arrival__terminal__name varchar NULL,
	flight__marketing_carrier__airline_id varchar NULL,
	flight__marketing_carrier__flight_number varchar NULL,
	flight__operating_carrier__airline_id varchar NULL,
	flight__equipment__aircraft_code varchar NULL,
	flight__details__stops__stop_quantity int8 NULL,
	flight__details__days_of_operation varchar NULL,
	flight__details__date_period__effective varchar NULL,
	flight__details__date_period__expiration varchar NULL,
	flight__equipment__on_board_equipment__inflight_entertainment bool NULL,
	flight__departure__terminal__name varchar NULL
);

insert into l1.flight_schedules_tmp(
	total_journey__duration,
	flight__departure__airport_code,
	flight__departure__scheduled_time_local__date_time,
	flight__arrival__airport_code,
	flight__arrival__scheduled_time_local__date_time,
	flight__arrival__terminal__name,
	flight__marketing_carrier__airline_id,
	flight__marketing_carrier__flight_number,
	flight__operating_carrier__airline_id,
	flight__equipment__aircraft_code,
	flight__details__stops__stop_quantity,
	flight__details__days_of_operation,
	flight__details__date_period__effective,
	flight__details__date_period__expiration,
	flight__equipment__on_board_equipment__inflight_entertainment,
	flight__departure__terminal__name
)
with unique_flights as (
	select distinct total_journey__duration,
		flight__departure__airport_code,
		flight__departure__scheduled_time_local__date_time,
		flight__arrival__airport_code,
		flight__arrival__scheduled_time_local__date_time,
		flight__arrival__terminal__name,
		flight__marketing_carrier__airline_id,
		flight__marketing_carrier__flight_number,
		flight__operating_carrier__airline_id,
		flight__equipment__aircraft_code,
		flight__details__stops__stop_quantity,
		flight__details__days_of_operation,
		flight__details__date_period__effective,
		flight__details__date_period__expiration,
		flight__equipment__on_board_equipment__inflight_entertainment,
		flight__departure__terminal__name from l1.flight_schedules
)
select * from unique_flights;
/*
delete from l1.operations_customer_flight_info;

insert into l1.operations_customer_flight_info(data)
	select data from l1.operations_customer_flight_info_tmp;
	
drop table l1.operations_customer_flight_info_tmp;
*/