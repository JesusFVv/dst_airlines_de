/* Create functions needed to be able to automatically calculate the routes between
two airports diretly with a simple SQL query (thus easily from Metabase)
Those functions need to be defined from initialization of the DB
Functions:
- flight_routes.query_routes_in_graph_db
- flight_routes.query_routes_between_airports

ex. query:
	SELECT num_flights, route, duration_hours FROM flight_routes.query_routes_between_airports('FRA', 'LAX', 3);
*/

LOAD 'age';
SET search_path = ag_catalog, "$user", public;

-- Example of a Query in the graph schema flight_routes
with graph_query as (
	SELECT *
	FROM cypher('flight_routes', $$
	    MATCH p = (:Airport {code: 'FRA'})-[*..3]->(:Airport {code: 'LAX'})
	    RETURN relationships(p)
	$$) as (routes agtype)
),
routes_text as (
	select
		row_number() over(order by routes) as idx,
		cast(routes as varchar) as routes
		from graph_query
),
nodes_splitted as (
	select idx, regexp_matches(routes, '(?:{\"route\": \"([A-Z\->\s]*))', 'g') as node,
		regexp_matches(routes, '(?:\"duration\": ([0-9\.]*))', 'g') as duration_hours
		from routes_text
),
routes_formatted as (
	select  count(*) as num_flights, 
		string_agg(node[1], ' || ') as route,
		sum(cast(duration_hours[1] as float)) as duration_hours
		from nodes_splitted
		group by idx
)
select distinct num_flights, route, duration_hours from routes_formatted
	where regexp_count(route, 'FRA') = 1 and regexp_count(route, 'LAX') = 1
	order by duration_hours asc, num_flights asc;


-- Create intermediate function to extract graph objects
CREATE OR REPLACE FUNCTION flight_routes.query_routes_in_graph_db(departure_code varchar, arrival_code varchar, number_flights int)
RETURNS TABLE(routes agtype)
LANGUAGE plpgsql
AS $function$
DECLARE sql VARCHAR;
BEGIN
        load 'age';
        SET search_path TO ag_catalog;
        sql := format('
			SELECT *
			FROM cypher(''flight_routes'', $$
			    MATCH p = (:Airport {code: "%1$s"})-[*..%3$s]->(:Airport {code: "%2$s"})
			    RETURN relationships(p)
			$$) as (routes agtype);
		', departure_code, arrival_code, number_flights);
        RETURN QUERY EXECUTE sql;

END
$function$;

--SELECT * FROM flight_routes.query_routes_in_graph_db('FRA', 'LAX', 2);  -- Test the function

-- Create function to query the number of routes between an origin and a destination, using the previous function
CREATE OR REPLACE FUNCTION flight_routes.query_routes_between_airports(departure_code varchar, arrival_code varchar, number_flights int)
RETURNS TABLE(num_flights int, route varchar, duration_hours float)
LANGUAGE plpgsql
AS $function$
BEGIN
	RETURN QUERY 
		with graph_query as (
			SELECT * FROM flight_routes.query_routes_in_graph_db(departure_code, arrival_code, number_flights)
		),
		routes_text as (
			select
				row_number() over(order by routes) as idx,
				cast(routes as varchar) as routes
				from graph_query
		),
		nodes_splitted as (
			select idx, regexp_matches(routes, '(?:{\"route\": \"([A-Z\->\s]*))', 'g') as node,
				regexp_matches(routes, '(?:\"duration\": ([0-9\.]*))', 'g') as duration_hours
				from routes_text
		),
		routes_formatted as (
			select  count(*)::int as num_flights, 
				string_agg(node[1], ' || ') as route,
				sum(cast(a.duration_hours[1] as float)) as duration_hours
				from nodes_splitted as a
				group by idx
		)
		select distinct a.num_flights::int, a.route::varchar, a.duration_hours::float
			from routes_formatted as a
			where regexp_count(a.route, departure_code) = 1 and regexp_count(a.route, arrival_code) = 1
			order by a.duration_hours asc, a.num_flights asc;
END
$function$
;
-- With the following query we get the available routes for an origin, destination and number max of flights in between
SELECT num_flights, route, duration_hours FROM flight_routes.query_routes_between_airports('FRA', 'LAX', 3);  -- Test the function

