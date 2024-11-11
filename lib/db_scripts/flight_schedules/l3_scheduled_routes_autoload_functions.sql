/* Function to automatically insert the new flight routes to l3.scheduled_routes, after being inserted in l2.flight_shceduled
 * If the flight route already exists in l3.scheduled_routes, the function updates its average duration in hours, with the new entries
 * in l2.flight_scheduled.(This Insert or Update is known as UPSERT)
 */
-- Create function for l3.scheduled_routes autoloading trigger applied to l2.flight_scheduled
CREATE OR REPLACE FUNCTION l2.autoload_l3_scheduled_routes()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
	insert into l3.scheduled_routes
		select departure_airport_code, arrival_airport_code, avg(flight_duration_hours) as avg_flight_duration_hours
			from l2.flight_schedules
			where departure_airport_code = new.departure_airport_code and arrival_airport_code = new.arrival_airport_code
			group by departure_airport_code, arrival_airport_code
			on conflict on constraint scheduled_routes_pkey do update set avg_flight_duration_hours = excluded.avg_flight_duration_hours;
	RETURN NULL;
EXCEPTION WHEN foreign_key_violation or invalid_foreign_key THEN
	RETURN NULL;
END;
$function$
;

-- Create trigger in l2.flight_scheduled to detect the new inserts
create trigger trigger_autoload_l3_scheduled_routes after
insert
    on
    l2.flight_schedules for each row execute function l2.autoload_l3_scheduled_routes();

