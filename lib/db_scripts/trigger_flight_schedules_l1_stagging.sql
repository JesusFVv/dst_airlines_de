-- Create Function to insert new rows in the stagging table of customer flight info
CREATE OR REPLACE FUNCTION l1.autoload_l1_flight_schedules()
	RETURNS trigger AS $function$
	BEGIN
		INSERT INTO l1._flight_schedules_stagging
		VALUES (NEW.*);
		RETURN NEW;
	END;
	$function$ LANGUAGE plpgsql;


-- Create a Trigger for the previous function
create trigger trigger_autoload_l1_stagging_flight_schedules after
insert
    on
    l1.flight_schedules for each row execute function l1.autoload_l1_flight_schedules();



-- -- Test: insert one row
-- insert into l1.operations_customer_flight_info (data)
-- 	select data from l1.operations_customer_flight_info order by id desc limit 5;
	