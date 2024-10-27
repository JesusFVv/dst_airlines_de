-- Create Function to insert new rows in the stagging table of customer flight info
CREATE OR REPLACE FUNCTION l1.autoload_l1_stagging_customer_flight_info()
 RETURNS trigger
AS $function$
	BEGIN
		INSERT INTO l1._operations_customer_flight_info_stagging(original_id, data)
		VALUES (NEW.id, NEW.data);
		RETURN NEW;
	END;
	$function$ LANGUAGE plpgsql
;
	
-- Create a Trigger for the previous function
create OR REPLACE TRIGGER trigger_autoload_l1_stagging_customer_flight_info
	after insert on l1.operations_customer_flight_info
    for each row
    execute function l1.autoload_l1_stagging_customer_flight_info();
   

-- Test: insert one row
insert into l1.operations_customer_flight_info (data)
	select data from l1.operations_customer_flight_info order by id desc limit 5;
	
