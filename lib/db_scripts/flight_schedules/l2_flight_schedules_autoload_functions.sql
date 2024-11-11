/*Logic of ingestion from l1 to l2 is different for flight_schedules than for customer_flight_information
Each row inserted in l1.flight_schedules will be caught by the trigger and then:
- The duration column will be normalized in table l2.flight_scheduled_dates
- The inserted row is normalized in the table l2.flight_schedules if possible
- If a foreign key error is encountered (ex. airline code is not in refdata), the row is inserted in l1.flight_schedules_stagging
*/

-- Create Function to normalize or stagging

CREATE FUNCTION l1.autoload_l1_flight_schedules_2() RETURNS trigger AS 
$flight_schedules_normalization$
BEGIN
	insert into l2.flight_scheduled_dates
		with dim_departure_local_dates as (
			select to_char(new.flight__departure__scheduled_time_local__date_time, 'yyyymmddHH24MISS') as date_idx, 
				new.flight__departure__scheduled_time_local__date_time as date_time
		),
		dim_arrival_local_dates as (
			select to_char(new.flight__arrival__scheduled_time_local__date_time, 'yyyymmddHH24MISS') as date_idx, 
				new.flight__arrival__scheduled_time_local__date_time as date_time
		),
		union_arrival_departure_dates as (
			select date_idx, date_time from dim_departure_local_dates union select date_idx, date_time from dim_arrival_local_dates
		)
		select date_idx, date_time from union_arrival_departure_dates
		on conflict on constraint flight_scheduled_dates_pkey do nothing;
    insert into l2.flight_schedules
		with row_values as (
			select new.*
		),
		normalized_flight_schedules as(
			select
				to_char(flight__departure__scheduled_time_local__date_time, 'yyyymmddHH24MISS') as departure_date_idx,
				flight__departure__airport_code as departure_airport_code,
				to_char(flight__arrival__scheduled_time_local__date_time, 'yyyymmddHH24MISS') as arrival_date_idx,
				flight__arrival__airport_code as arrival_airport_code,
				coalesce(flight__operating_carrier__airline_id, flight__marketing_carrier__airline_id) as airline_code,
				round(coalesce((regexp_match(total_journey__duration, 'PT(?:(\d*)H)?(?:(\d*)M)?'))[1]::int, 0) 
					+ coalesce((regexp_match(total_journey__duration, 'PT(?:(\d*)H)?(?:(\d*)M)?'))[2]::decimal, 0) * 1/60, 2) as fligh_duration_hours,
				case when flight__details__days_of_operation like '%1%' then true else false end as monday,
				case when flight__details__days_of_operation like '%2%' then true else false end as tuesday,
				case when flight__details__days_of_operation like '%3%' then true else false end as wednesday,
				case when flight__details__days_of_operation like '%4%' then true else false end as thursday,
				case when flight__details__days_of_operation like '%5%' then true else false end as friday,
				case when flight__details__days_of_operation like '%6%' then true else false end as saturday,
				case when flight__details__days_of_operation like '%7%' then true else false end as sunday
				from row_values
		)
		select * from normalized_flight_schedules
	on conflict on constraint flight_schedules_pkey do nothing;
	RETURN NULL;
EXCEPTION WHEN foreign_key_violation or invalid_foreign_key THEN
	insert into l1."_flight_schedules_stagging" select new.*;
	RETURN NULL;
END;
$flight_schedules_normalization$ LANGUAGE plpgsql;


-- Create a Trigger for the previous function
create trigger trigger_autoload_l1_normalize_or_stagging_flight_schedules after
insert
    on
    l1.flight_schedules for each row execute function l1.autoload_l1_flight_schedules_2()


	