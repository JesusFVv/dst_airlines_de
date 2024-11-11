-- Activate AGE connection
CREATE EXTENSION age;
LOAD 'age';
SET search_path = ag_catalog, "$user", public;
-- Create graph db
SELECT create_graph('flight_routes');

-- Function to create Airports (vertex)
CREATE OR REPLACE FUNCTION flight_routes.create_vertex(airport_code text)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE sql VARCHAR;
BEGIN
    load 'age';
    SET search_path TO ag_catalog;
	sql := format('
		SELECT *
		FROM cypher(''flight_routes'', $$
			CREATE (:Airport {code:"%1$s"})
		$$) AS (v agtype);
	', airport_code);
	EXECUTE sql;
END
$function$
;
-- Function to create edges (flight routes)
CREATE OR REPLACE FUNCTION flight_routes.create_edges(departure_code text, arrival_code text, duration_hours float)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE sql VARCHAR;
BEGIN
    load 'age';
    SET search_path TO ag_catalog;
	sql := format('
		SELECT *
		FROM cypher(''flight_routes'', $$
			    MATCH (a:Airport), (b:Airport)
			    WHERE a.code = "%1$s" AND b.code = "%2$s"
			    CREATE (a)-[:ROUTE {duration: %3$s, route:"%1$s -> %2$s"}]->(b)
		$$) AS (e agtype);
	', departure_code, arrival_code, duration_hours);
	EXECUTE sql;
END
$function$
;
-- Create needed labels for nodes and edges
select create_vlabel('flight_routes','Airport');
select create_elabel('flight_routes','ROUTE');
