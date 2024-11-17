/*
 * Remove duplicated values in data column for the table l1.operations_customer_flight_info
 * */
CREATE TABLE l1.operations_customer_flight_info_tmp (
	"data" jsonb NOT NULL
);

insert into l1.operations_customer_flight_info_tmp(data)
with unique_flights as (
	select distinct data from l1.operations_customer_flight_info
)
select data from unique_flights;

delete from l1.operations_customer_flight_info;

insert into l1.operations_customer_flight_info(data)
	select data from l1.operations_customer_flight_info_tmp;
	
drop table l1.operations_customer_flight_info_tmp;