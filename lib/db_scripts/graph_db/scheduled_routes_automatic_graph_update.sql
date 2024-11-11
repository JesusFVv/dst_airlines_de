/*
 * Create the functions to automatically insert as vertex and edges the new routes imported form the relational db to the table public.sheduled_routes
*/

LOAD 'age';
SET search_path = ag_catalog, "$user", public;

-- Create intermediate function to extract graph objects
CREATE OR REPLACE FUNCTION flight_routes.query_vertex_in_graph_db(airport_code varchar)
RETURNS TABLE(code agtype)
LANGUAGE plpgsql
AS $function$
DECLARE sql VARCHAR;
BEGIN
        load 'age';
        SET search_path TO ag_catalog;
        sql := format('
			SELECT *
			FROM cypher(''flight_routes'', $$
			    MATCH (n:Airport {code: "%1$s"})
			    RETURN n
			$$) as (code agtype);
		', airport_code);
        RETURN QUERY EXECUTE sql;
END
$function$;


-- Create function for l3.scheduled_routes autoloading trigger applied to l2.flight_scheduled
CREATE OR REPLACE FUNCTION flight_routes.autoload_scheduled_routes()
RETURNS trigger
AS $function$
DECLARE
	airport_code varchar;
	vertex int := 0;
	edge int := 0;
BEGIN
	LOAD 'age';
	SET search_path = ag_catalog, "$user", public;

	FOREACH airport_code IN ARRAY ARRAY[NEW.departure_airport_code, NEW.arrival_airport_code]
	LOOP
		vertex := 0;
		select count(*) INTO vertex FROM flight_routes.query_vertex_in_graph_db(airport_code);
		IF vertex = 0 THEN
			PERFORM flight_routes.create_vertex(airport_code);
		END IF;
	END LOOP;
	SELECT count(*) INTO edge FROM flight_routes.query_routes_in_graph_db(NEW.departure_airport_code, NEW.arrival_airport_code, 1);
	IF edge = 0 THEN
		PERFORM flight_routes.create_edge(NEW.departure_airport_code, NEW.arrival_airport_code, NEW.avg_flight_duration_hours);
	ELSE
		PERFORM flight_routes.update_edge_property(NEW.departure_airport_code, NEW.arrival_airport_code, NEW.avg_flight_duration_hours);
	END IF;
	RETURN NULL;
END;
$function$ LANGUAGE plpgsql
;


-- Create trigger in public.scheduled_routes to detect the new inserts
create trigger trigger_autoload_scheduled_routes after
insert or update
    on
    public.scheduled_routes for each row execute function flight_routes.autoload_scheduled_routes();

-- Test trigger in public.scheduled_routes
insert into public.scheduled_routes values ('GRU', 'ATL', 9.93) on conflict (departure_airport_code, arrival_airport_code) do update set avg_flight_duration_hours = excluded.avg_flight_duration_hours;

select * from public.scheduled_routes sr limit 5;
   

   
   
