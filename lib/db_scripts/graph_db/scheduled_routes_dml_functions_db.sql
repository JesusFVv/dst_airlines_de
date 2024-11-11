-- Activate AGE connection
LOAD 'age';
SET search_path = ag_catalog, "$user", public;
-- Create the Airports as nodes
with airports_codes as (
	select distinct departure_airport_code as airport_code
		from public.scheduled_routes_tmp srt
	union
	select distinct arrival_airport_code as airport_code
		from public.scheduled_routes_tmp srt
)
select flight_routes.create_vertex(airport_code) from airports_codes;
-- Create routes as edges
/* This function create duplicates randomly
select flight_routes.create_edges(departure_airport_code, arrival_airport_code, avg_flight_duration_hours)
	from public.scheduled_routes_tmp srt;
*/
-- PLPSQL script to loop throught the available routes and avoid duplicates
do $$
declare 
	temprow record;
begin
	for temprow in
		select departure_airport_code, arrival_airport_code, avg_flight_duration_hours from public.scheduled_routes_tmp
			order by departure_airport_code, arrival_airport_code
	loop
		perform flight_routes.create_edges(temprow.departure_airport_code, temprow.arrival_airport_code, temprow.avg_flight_duration_hours);
	end loop;
end; 
$$ LANGUAGE plpgsql;

-- Drop a graph
--SELECT * FROM ag_catalog.drop_graph('flight_routes', true);
