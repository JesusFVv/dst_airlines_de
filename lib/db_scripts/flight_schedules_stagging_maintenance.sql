/* From time to time
    - look to the stagging,
    - analyze why couldnt go though to l2 (what missing foreign keys we need)
    - Create the missing foreing keys
    - Follow steps below to recompute stagged rows
*/
create table l1."_flight_schedules_stagging_tmp" as
	select * from l1."_flight_schedules_stagging" fss;
	
delete from l1."_flight_schedules_stagging" ;

-- l1.flight_schedules definition

-- Drop table

-- DROP TABLE l1.flight_schedules;

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
	"_dlt_load_id" varchar NOT NULL,
	"_dlt_id" varchar NOT NULL,
	flight__equipment__on_board_equipment__inflight_entertainment bool NULL,
	flight__departure__terminal__name varchar NULL,
	CONSTRAINT flight_schedules_tmp__dlt_id_key UNIQUE (_dlt_id)
);

-- Table Triggers

create trigger trigger_autoload_l1_normalize_or_stagging_flight_schedules after
insert
    on
    l1.flight_schedules_tmp for each row execute function l1.autoload_l1_flight_schedules_2();

insert into l1.flight_schedules_tmp 
	select * from l1."_flight_schedules_stagging_tmp";
	

insert into l1.flight_schedules
	select * from l1."_flight_schedules_stagging_tmp" where "_dlt_id" = 'KMWtQb7P4gLi1w';

drop table l1.flight_schedules_tmp;
drop table l1."_flight_schedules_stagging_tmp" ;


create table l1."_flight_schedules_stagging_tmp" as
	select * from l1.flight_schedules limit 1;

insert into l1.flight_schedules 
	select * from l1."_flight_schedules_stagging_tmp";
	