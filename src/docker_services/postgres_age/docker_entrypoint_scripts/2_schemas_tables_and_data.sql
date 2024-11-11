--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3 (Debian 16.3-1.pgdg120+1)
-- Dumped by pg_dump version 16.3 (Debian 16.3-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ag_catalog; Type: SCHEMA; Schema: -; Owner: dst_graph_designer
--

-- CREATE SCHEMA ag_catalog;


ALTER SCHEMA ag_catalog OWNER TO dst_graph_designer;

--
-- Name: flight_routes; Type: SCHEMA; Schema: -; Owner: dst_graph_designer
--

CREATE SCHEMA flight_routes;


ALTER SCHEMA flight_routes OWNER TO dst_graph_designer;

--
-- Name: l3; Type: SCHEMA; Schema: -; Owner: dst_graph_designer
--

CREATE SCHEMA l3;


ALTER SCHEMA l3 OWNER TO dst_graph_designer;

--
-- Name: age; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS age WITH SCHEMA ag_catalog;


--
-- Name: EXTENSION age; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION age IS 'AGE database extension';


--
-- Name: autoload_scheduled_routes(); Type: FUNCTION; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE FUNCTION flight_routes.autoload_scheduled_routes() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION flight_routes.autoload_scheduled_routes() OWNER TO dst_graph_designer;

--
-- Name: create_edges(text, text, double precision); Type: FUNCTION; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE FUNCTION flight_routes.create_edges(departure_code text, arrival_code text, duration_hours double precision) RETURNS void
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION flight_routes.create_edges(departure_code text, arrival_code text, duration_hours double precision) OWNER TO dst_graph_designer;

--
-- Name: create_vertex(text); Type: FUNCTION; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE FUNCTION flight_routes.create_vertex(airport_code text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION flight_routes.create_vertex(airport_code text) OWNER TO dst_graph_designer;

--
-- Name: query_routes_between_airports(character varying, character varying, integer); Type: FUNCTION; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE FUNCTION flight_routes.query_routes_between_airports(departure_code character varying, arrival_code character varying, number_flights integer) RETURNS TABLE(num_flights integer, route character varying, duration_hours double precision)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION flight_routes.query_routes_between_airports(departure_code character varying, arrival_code character varying, number_flights integer) OWNER TO dst_graph_designer;

--
-- Name: query_routes_in_graph_db(character varying, character varying, integer); Type: FUNCTION; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE FUNCTION flight_routes.query_routes_in_graph_db(departure_code character varying, arrival_code character varying, number_flights integer) RETURNS TABLE(routes ag_catalog.agtype)
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION flight_routes.query_routes_in_graph_db(departure_code character varying, arrival_code character varying, number_flights integer) OWNER TO dst_graph_designer;

--
-- Name: query_vertex_in_graph_db(character varying); Type: FUNCTION; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE FUNCTION flight_routes.query_vertex_in_graph_db(airport_code character varying) RETURNS TABLE(code ag_catalog.agtype)
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION flight_routes.query_vertex_in_graph_db(airport_code character varying) OWNER TO dst_graph_designer;

--
-- Name: update_edge_property(text, text, double precision); Type: FUNCTION; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE FUNCTION flight_routes.update_edge_property(departure_code text, arrival_code text, duration_hours double precision) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE sql VARCHAR;
BEGIN
    load 'age';
    SET search_path TO ag_catalog;
	sql := format('
		SELECT * 
			FROM cypher(''flight_routes'', $$
				MATCH (:Airport {code: "%1$s"})-[e:ROUTE]->(:Airport {code: "%2$s"})
				SET e.duration = %3$s
				RETURN e
				$$) as (e agtype);
	', departure_code, arrival_code, duration_hours);
	EXECUTE sql;
END
$_$;


ALTER FUNCTION flight_routes.update_edge_property(departure_code text, arrival_code text, duration_hours double precision) OWNER TO dst_graph_designer;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _ag_label_vertex; Type: TABLE; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE TABLE flight_routes._ag_label_vertex (
    id ag_catalog.graphid NOT NULL,
    properties ag_catalog.agtype DEFAULT ag_catalog.agtype_build_map() NOT NULL
);


ALTER TABLE flight_routes._ag_label_vertex OWNER TO dst_graph_designer;

--
-- Name: Airport; Type: TABLE; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE TABLE flight_routes."Airport" (
)
INHERITS (flight_routes._ag_label_vertex);


ALTER TABLE flight_routes."Airport" OWNER TO dst_graph_designer;

--
-- Name: Airport_id_seq; Type: SEQUENCE; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE SEQUENCE flight_routes."Airport_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 281474976710655
    CACHE 1;


ALTER SEQUENCE flight_routes."Airport_id_seq" OWNER TO dst_graph_designer;

--
-- Name: Airport_id_seq; Type: SEQUENCE OWNED BY; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER SEQUENCE flight_routes."Airport_id_seq" OWNED BY flight_routes."Airport".id;


--
-- Name: _ag_label_edge; Type: TABLE; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE TABLE flight_routes._ag_label_edge (
    id ag_catalog.graphid NOT NULL,
    start_id ag_catalog.graphid NOT NULL,
    end_id ag_catalog.graphid NOT NULL,
    properties ag_catalog.agtype DEFAULT ag_catalog.agtype_build_map() NOT NULL
);


ALTER TABLE flight_routes._ag_label_edge OWNER TO dst_graph_designer;

--
-- Name: ROUTE; Type: TABLE; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE TABLE flight_routes."ROUTE" (
)
INHERITS (flight_routes._ag_label_edge);


ALTER TABLE flight_routes."ROUTE" OWNER TO dst_graph_designer;

--
-- Name: ROUTE_id_seq; Type: SEQUENCE; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE SEQUENCE flight_routes."ROUTE_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 281474976710655
    CACHE 1;


ALTER SEQUENCE flight_routes."ROUTE_id_seq" OWNER TO dst_graph_designer;

--
-- Name: ROUTE_id_seq; Type: SEQUENCE OWNED BY; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER SEQUENCE flight_routes."ROUTE_id_seq" OWNED BY flight_routes."ROUTE".id;


--
-- Name: _ag_label_edge_id_seq; Type: SEQUENCE; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE SEQUENCE flight_routes._ag_label_edge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 281474976710655
    CACHE 1;


ALTER SEQUENCE flight_routes._ag_label_edge_id_seq OWNER TO dst_graph_designer;

--
-- Name: _ag_label_edge_id_seq; Type: SEQUENCE OWNED BY; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER SEQUENCE flight_routes._ag_label_edge_id_seq OWNED BY flight_routes._ag_label_edge.id;


--
-- Name: _ag_label_vertex_id_seq; Type: SEQUENCE; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE SEQUENCE flight_routes._ag_label_vertex_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 281474976710655
    CACHE 1;


ALTER SEQUENCE flight_routes._ag_label_vertex_id_seq OWNER TO dst_graph_designer;

--
-- Name: _ag_label_vertex_id_seq; Type: SEQUENCE OWNED BY; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER SEQUENCE flight_routes._ag_label_vertex_id_seq OWNED BY flight_routes._ag_label_vertex.id;


--
-- Name: _label_id_seq; Type: SEQUENCE; Schema: flight_routes; Owner: dst_graph_designer
--

CREATE SEQUENCE flight_routes._label_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 65535
    CACHE 1
    CYCLE;


ALTER SEQUENCE flight_routes._label_id_seq OWNER TO dst_graph_designer;

--
-- Name: scheduled_routes; Type: TABLE; Schema: l3; Owner: dst_graph_designer
--

CREATE TABLE l3.scheduled_routes (
    departure_airport_code character varying(50) NOT NULL,
    arrival_airport_code character varying(50) NOT NULL,
    avg_flight_duration_hours numeric
);


ALTER TABLE l3.scheduled_routes OWNER TO dst_graph_designer;

--
-- Name: scheduled_routes; Type: TABLE; Schema: public; Owner: dst_graph_designer
--

CREATE TABLE public.scheduled_routes (
    departure_airport_code character varying(50) NOT NULL,
    arrival_airport_code character varying(50) NOT NULL,
    avg_flight_duration_hours numeric
);


ALTER TABLE public.scheduled_routes OWNER TO dst_graph_designer;

--
-- Name: Airport id; Type: DEFAULT; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER TABLE ONLY flight_routes."Airport" ALTER COLUMN id SET DEFAULT ag_catalog._graphid((ag_catalog._label_id('flight_routes'::name, 'Airport'::name))::integer, nextval('flight_routes."Airport_id_seq"'::regclass));


--
-- Name: Airport properties; Type: DEFAULT; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER TABLE ONLY flight_routes."Airport" ALTER COLUMN properties SET DEFAULT ag_catalog.agtype_build_map();


--
-- Name: ROUTE id; Type: DEFAULT; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER TABLE ONLY flight_routes."ROUTE" ALTER COLUMN id SET DEFAULT ag_catalog._graphid((ag_catalog._label_id('flight_routes'::name, 'ROUTE'::name))::integer, nextval('flight_routes."ROUTE_id_seq"'::regclass));


--
-- Name: ROUTE properties; Type: DEFAULT; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER TABLE ONLY flight_routes."ROUTE" ALTER COLUMN properties SET DEFAULT ag_catalog.agtype_build_map();


--
-- Name: _ag_label_edge id; Type: DEFAULT; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER TABLE ONLY flight_routes._ag_label_edge ALTER COLUMN id SET DEFAULT ag_catalog._graphid((ag_catalog._label_id('flight_routes'::name, '_ag_label_edge'::name))::integer, nextval('flight_routes._ag_label_edge_id_seq'::regclass));


--
-- Name: _ag_label_vertex id; Type: DEFAULT; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER TABLE ONLY flight_routes._ag_label_vertex ALTER COLUMN id SET DEFAULT ag_catalog._graphid((ag_catalog._label_id('flight_routes'::name, '_ag_label_vertex'::name))::integer, nextval('flight_routes._ag_label_vertex_id_seq'::regclass));


--
-- Data for Name: ag_graph; Type: TABLE DATA; Schema: ag_catalog; Owner: dst_graph_designer
--

COPY ag_catalog.ag_graph (graphid, name, namespace) FROM stdin;
17040	flight_routes	flight_routes
\.


--
-- Data for Name: ag_label; Type: TABLE DATA; Schema: ag_catalog; Owner: dst_graph_designer
--

COPY ag_catalog.ag_label (name, graph, id, kind, relation, seq_name) FROM stdin;
_ag_label_vertex	17040	1	v	flight_routes._ag_label_vertex	_ag_label_vertex_id_seq
_ag_label_edge	17040	2	e	flight_routes._ag_label_edge	_ag_label_edge_id_seq
Airport	17040	3	v	flight_routes."Airport"	Airport_id_seq
ROUTE	17040	4	e	flight_routes."ROUTE"	ROUTE_id_seq
\.


--
-- Data for Name: Airport; Type: TABLE DATA; Schema: flight_routes; Owner: dst_graph_designer
--

COPY flight_routes."Airport" (id, properties) FROM stdin;
844424930131969	{"code": "GRU"}
844424930131970	{"code": "ATL"}
844424930131971	{"code": "CLT"}
844424930131972	{"code": "JFK"}
844424930131973	{"code": "MCO"}
844424930131974	{"code": "FRA"}
844424930131975	{"code": "EWR"}
844424930131976	{"code": "VIE"}
844424930131977	{"code": "LHR"}
844424930131978	{"code": "MUC"}
844424930131979	{"code": "SEA"}
844424930131980	{"code": "LAX"}
844424930131981	{"code": "LAS"}
844424930131982	{"code": "ATH"}
844424930131983	{"code": "DEN"}
844424930131984	{"code": "DXB"}
844424930131985	{"code": "MIA"}
844424930131986	{"code": "MAD"}
844424930131987	{"code": "ZRH"}
844424930131988	{"code": "DFW"}
844424930131989	{"code": "SFO"}
844424930131990	{"code": "BOG"}
844424930131991	{"code": "CAI"}
844424930131992	{"code": "MEX"}
844424930131993	{"code": "CDG"}
844424930131994	{"code": "ORD"}
844424930131995	{"code": "CMN"}
844424930131996	{"code": "OSL"}
844424930131997	{"code": "ARN"}
844424930131998	{"code": "AMS"}
844424930131999	{"code": "ONT"}
844424930132000	{"code": "LOS"}
844424930132001	{"code": "FCO"}
844424930132002	{"code": "DUB"}
844424930132003	{"code": "PVG"}
844424930132004	{"code": "BER"}
844424930132005	{"code": "LIS"}
844424930132006	{"code": "BKK"}
844424930132007	{"code": "AGY"}
844424930132008	{"code": "SAW"}
844424930132009	{"code": "PAE"}
844424930132010	{"code": "NLU"}
844424930132011	{"code": "MAN"}
844424930132012	{"code": "MRU"}
844424930132013	{"code": "HND"}
844424930132014	{"code": "DEL"}
844424930132015	{"code": "DMK"}
844424930132016	{"code": "WAW"}
844424930132017	{"code": "IST"}
844424930132018	{"code": "CPT"}
844424930132019	{"code": "SSH"}
844424930132020	{"code": "NBO"}
844424930132021	{"code": "NCE"}
844424930132022	{"code": "DMM"}
844424930132023	{"code": "PEK"}
844424930132024	{"code": "EKW"}
844424930132025	{"code": "AVT"}
844424930132026	{"code": "ALG"}
844424930132027	{"code": "ZMU"}
844424930132028	{"code": "DAL"}
844424930132029	{"code": "QPP"}
\.


--
-- Data for Name: ROUTE; Type: TABLE DATA; Schema: flight_routes; Owner: dst_graph_designer
--

COPY flight_routes."ROUTE" (id, start_id, end_id, properties) FROM stdin;
1125899906843048	844424930132029	844424930131974	{"route": "QPP -> FRA", "duration": 4.451863517060367}
1125899906842715	844424930131989	844424930131981	{"route": "SFO -> LAS", "duration": 1.8336498761354254}
1125899906842636	844424930131985	844424930131969	{"route": "MIA -> GRU", "duration": 8.32072758037225}
1125899906842680	844424930131981	844424930131983	{"route": "LAS -> DEN", "duration": 2.0029906542056075}
1125899906842712	844424930131978	844424930132006	{"route": "MUC -> BKK", "duration": 10.5}
1125899906842686	844424930131976	844424930131975	{"route": "VIE -> EWR", "duration": 9.75}
1125899906842722	844424930131994	844424930131972	{"route": "ORD -> JFK", "duration": 2.3604174228675134}
1125899906842660	844424930131994	844424930131969	{"route": "ORD -> GRU", "duration": 10.25}
1125899906842687	844424930131994	844424930131993	{"route": "ORD -> CDG", "duration": 8.08}
1125899906842664	844424930131969	844424930131980	{"route": "GRU -> LAX", "duration": 12.33}
1125899906842681	844424930131989	844424930131971	{"route": "SFO -> CLT", "duration": 5.089863760217984}
1125899906842630	844424930131979	844424930131980	{"route": "SEA -> LAX", "duration": 2.9741778127458693}
1125899906842675	844424930131978	844424930131994	{"route": "MUC -> ORD", "duration": 9.788421052631579}
1125899906842701	844424930132009	844424930131981	{"route": "PAE -> LAS", "duration": 2.5427857142857144}
1125899906842667	844424930131974	844424930132003	{"route": "FRA -> PVG", "duration": 11.469403973509934}
1125899906842700	844424930131990	844424930131970	{"route": "BOG -> ATL", "duration": 5.1445751633986925}
1125899906842632	844424930131982	844424930131975	{"route": "ATH -> EWR", "duration": 11.17}
1125899906842693	844424930131979	844424930131971	{"route": "SEA -> CLT", "duration": 5.002489270386266}
1125899906842635	844424930131978	844424930131984	{"route": "MUC -> DXB", "duration": 5.83}
1125899906842708	844424930131993	844424930131987	{"route": "CDG -> ZRH", "duration": 1.3111963190184048}
1125899906842669	844424930131976	844424930132004	{"route": "VIE -> BER", "duration": 1.2523420074349443}
1125899906842653	844424930131976	844424930131997	{"route": "VIE -> ARN", "duration": 2.25}
1125899906842966	844424930131972	844424930131983	{"route": "JFK -> DEN", "duration": 4.716770538243626}
1125899906842831	844424930131973	844424930131970	{"route": "MCO -> ATL", "duration": 1.6548051118210862}
1125899906843023	844424930132004	844424930131974	{"route": "BER -> FRA", "duration": 1.25}
1125899906842726	844424930131972	844424930131980	{"route": "JFK -> LAX", "duration": 6.3740223792697295}
1125899906842791	844424930131973	844424930131975	{"route": "MCO -> EWR", "duration": 2.75911800486618}
1125899906842764	844424930131972	844424930131981	{"route": "JFK -> LAS", "duration": 5.995643896976484}
1125899906842626	844424930131971	844424930131972	{"route": "CLT -> JFK", "duration": 1.9648586810228803}
1125899906842905	844424930131979	844424930131989	{"route": "SEA -> SFO", "duration": 2.301114186851211}
1125899906842710	844424930131998	844424930131974	{"route": "AMS -> FRA", "duration": 1.17}
1125899906842631	844424930131971	844424930131981	{"route": "CLT -> LAS", "duration": 5.023903846153846}
1125899906842640	844424930131990	844424930131985	{"route": "BOG -> MIA", "duration": 3.947887640449438}
1125899906842644	844424930131992	844424930131969	{"route": "MEX -> GRU", "duration": 9.57875}
1125899906842713	844424930131981	844424930131980	{"route": "LAS -> LAX", "duration": 1.3324413145539906}
1125899906842684	844424930131976	844424930132006	{"route": "VIE -> BKK", "duration": 10.08}
1125899906842691	844424930131977	844424930131994	{"route": "LHR -> ORD", "duration": 9.42}
1125899906842647	844424930131976	844424930131994	{"route": "VIE -> ORD", "duration": 10.17}
1125899906842702	844424930131973	844424930131985	{"route": "MCO -> MIA", "duration": 2.7197974683544306}
1125899906842683	844424930131974	844424930132005	{"route": "FRA -> LIS", "duration": 3.220228310502283}
1125899906842677	844424930131981	844424930131994	{"route": "LAS -> ORD", "duration": 3.816039024390244}
1125899906842697	844424930131978	844424930132003	{"route": "MUC -> PVG", "duration": 11.433529411764706}
1125899906842682	844424930131973	844424930131992	{"route": "MCO -> MEX", "duration": 3.9294927536231885}
1125899906842666	844424930131990	844424930131973	{"route": "BOG -> MCO", "duration": 4.271213389121339}
1125899906842809	844424930131972	844424930131985	{"route": "JFK -> MIA", "duration": 3.3304619124797408}
1125899906842692	844424930131975	844424930131970	{"route": "EWR -> ATL", "duration": 2.5515800561797755}
1125899906842951	844424930131980	844424930131994	{"route": "LAX -> ORD", "duration": 4.153823129251701}
1125899906842765	844424930131975	844424930131973	{"route": "EWR -> MCO", "duration": 3.079343863912515}
1125899906842714	844424930131975	844424930132004	{"route": "EWR -> BER", "duration": 8.08}
1125899906842628	844424930131975	844424930131976	{"route": "EWR -> VIE", "duration": 8.098214285714286}
1125899906842716	844424930131973	844424930131990	{"route": "MCO -> BOG", "duration": 3.990334728033473}
1125899906842657	844424930131994	844424930131980	{"route": "ORD -> LAX", "duration": 4.634326337169939}
1125899906842627	844424930131973	844424930131974	{"route": "MCO -> FRA", "duration": 9.08}
1125899906843004	844424930132006	844424930132014	{"route": "BKK -> DEL", "duration": 4.6048434925864905}
1125899906843037	844424930131994	844424930131970	{"route": "ORD -> ATL", "duration": 2.0775648535564852}
1125899906842625	844424930131969	844424930131970	{"route": "GRU -> ATL", "duration": 9.933414634146342}
1125899906842840	844424930131970	844424930131985	{"route": "ATL -> MIA", "duration": 1.9981752873563219}
1125899906842757	844424930131988	844424930131983	{"route": "DFW -> DEN", "duration": 2.217272047832586}
1125899906842786	844424930131983	844424930131979	{"route": "DEN -> SEA", "duration": 3.381436567164179}
1125899906843009	844424930131984	844424930132006	{"route": "DXB -> BKK", "duration": 6.084}
1125899906842934	844424930131994	844424930131973	{"route": "ORD -> MCO", "duration": 2.9216180371352785}
1125899906842997	844424930132017	844424930131974	{"route": "IST -> FRA", "duration": 3.377240663900415}
1125899906842999	844424930131970	844424930131971	{"route": "ATL -> CLT", "duration": 1.2751778329197685}
1125899906842888	844424930131988	844424930131981	{"route": "DFW -> LAS", "duration": 3.0950502706883216}
1125899906842994	844424930131984	844424930132014	{"route": "DXB -> DEL", "duration": 3.219076923076923}
1125899906842849	844424930132023	844424930132006	{"route": "PEK -> BKK", "duration": 5.322724935732648}
1125899906842777	844424930131980	844424930131988	{"route": "LAX -> DFW", "duration": 3.0984633757961784}
1125899906842736	844424930131970	844424930131975	{"route": "ATL -> EWR", "duration": 2.2232052161976665}
1125899906842907	844424930131988	844424930131973	{"route": "DFW -> MCO", "duration": 2.66087260034904}
1125899906842855	844424930131984	844424930131978	{"route": "DXB -> MUC", "duration": 6.75}
1125899906842633	844424930131983	844424930131977	{"route": "DEN -> LHR", "duration": 9.08}
1125899906842642	844424930131970	844424930131979	{"route": "ATL -> SEA", "duration": 5.750975975975976}
1125899906842689	844424930132008	844424930131974	{"route": "SAW -> FRA", "duration": 3.377532894736842}
1125899906842655	844424930131999	844424930131988	{"route": "ONT -> DFW", "duration": 2.970594965675057}
1125899906842638	844424930131988	844424930131979	{"route": "DFW -> SEA", "duration": 4.500112359550561}
1125899906842718	844424930132013	844424930131974	{"route": "HND -> FRA", "duration": 14.674655870445344}
1125899906842720	844424930132014	844424930131978	{"route": "DEL -> MUC", "duration": 8.92}
1125899906842873	844424930131995	844424930132017	{"route": "CMN -> IST", "duration": 4.570576923076923}
1125899906842658	844424930132000	844424930131974	{"route": "LOS -> FRA", "duration": 6.58}
1125899906843086	844424930131979	844424930131973	{"route": "SEA -> MCO", "duration": 5.672635135135135}
1125899906843147	844424930131975	844424930132002	{"route": "EWR -> DUB", "duration": 6.75}
1125899906843161	844424930131971	844424930131994	{"route": "CLT -> ORD", "duration": 2.224464285714286}
1125899906843099	844424930131989	844424930132009	{"route": "SFO -> PAE", "duration": 2.2594202898550724}
1125899906843103	844424930131990	844424930131988	{"route": "BOG -> DFW", "duration": 5.913855421686747}
1125899906843140	844424930131989	844424930131973	{"route": "SFO -> MCO", "duration": 5.3632697547683925}
1125899906843152	844424930131989	844424930131974	{"route": "SFO -> FRA", "duration": 10.981785714285714}
1125899906843151	844424930131979	844424930131983	{"route": "SEA -> DEN", "duration": 2.730883534136546}
1125899906843137	844424930131975	844424930131983	{"route": "EWR -> DEN", "duration": 4.441337047353761}
1125899906843181	844424930131998	844424930131994	{"route": "AMS -> ORD", "duration": 9.42}
1125899906843142	844424930131977	844424930131980	{"route": "LHR -> LAX", "duration": 11.33}
1125899906843121	844424930131978	844424930131986	{"route": "MUC -> MAD", "duration": 2.75}
1125899906843070	844424930131996	844424930131976	{"route": "OSL -> VIE", "duration": 2.33}
1125899906843149	844424930131978	844424930132001	{"route": "MUC -> FCO", "duration": 1.5}
1125899906843185	844424930131978	844424930132005	{"route": "MUC -> LIS", "duration": 3.33}
1125899906843141	844424930131978	844424930131993	{"route": "MUC -> CDG", "duration": 1.67}
1125899906843182	844424930131978	844424930131976	{"route": "MUC -> VIE", "duration": 1.0532083333333333}
1125899906843175	844424930132004	844424930131978	{"route": "BER -> MUC", "duration": 1.17}
1125899906843087	844424930131997	844424930131974	{"route": "ARN -> FRA", "duration": 2.25}
1125899906843067	844424930132005	844424930131978	{"route": "LIS -> MUC", "duration": 3.1816962025316458}
1125899906843128	844424930132002	844424930131975	{"route": "DUB -> EWR", "duration": 7.83}
1125899906843155	844424930132001	844424930131978	{"route": "FCO -> MUC", "duration": 1.58}
1125899906843104	844424930131987	844424930131986	{"route": "ZRH -> MAD", "duration": 2.42}
1125899906843123	844424930132016	844424930131976	{"route": "WAW -> VIE", "duration": 1.3318587360594796}
1125899906843058	844424930131987	844424930131976	{"route": "ZRH -> VIE", "duration": 1.3433385335413417}
1125899906843199	844424930131994	844424930131990	{"route": "ORD -> BOG", "duration": 5.83}
1125899906842797	844424930132006	844424930132013	{"route": "BKK -> HND", "duration": 5.659208103130755}
1125899906843194	844424930132017	844424930132019	{"route": "IST -> SSH", "duration": 2.7084}
1125899906843190	844424930132014	844424930131974	{"route": "DEL -> FRA", "duration": 9.156024844720497}
1125899906843210	844424930132026	844424930131974	{"route": "ALG -> FRA", "duration": 2.75}
1125899906843203	844424930131994	844424930131989	{"route": "ORD -> SFO", "duration": 4.868540218470705}
1125899906842948	844424930131985	844424930131990	{"route": "MIA -> BOG", "duration": 3.706615620214395}
1125899906842641	844424930131991	844424930131976	{"route": "CAI -> VIE", "duration": 3.75}
1125899906842723	844424930131972	844424930131990	{"route": "JFK -> BOG", "duration": 5.896}
1125899906842629	844424930131977	844424930131978	{"route": "LHR -> MUC", "duration": 1.83}
1125899906842690	844424930131987	844424930131991	{"route": "ZRH -> CAI", "duration": 4.002048192771085}
1125899906842673	844424930131987	844424930131994	{"route": "ZRH -> ORD", "duration": 10.08}
1125899906842648	844424930131974	844424930131995	{"route": "FRA -> CMN", "duration": 3.75}
1125899906842705	844424930131971	844424930131970	{"route": "CLT -> ATL", "duration": 1.3937907949790795}
1125899906842643	844424930131973	844424930131981	{"route": "MCO -> LAS", "duration": 6.465179282868526}
1125899906842656	844424930131979	844424930131978	{"route": "SEA -> MUC", "duration": 10.08}
1125899906842639	844424930131989	844424930131988	{"route": "SFO -> DFW", "duration": 3.5886527929901426}
1125899906842717	844424930131977	844424930131976	{"route": "LHR -> VIE", "duration": 2.232480211081794}
1125899906842645	844424930131978	844424930131974	{"route": "MUC -> FRA", "duration": 1.08}
1125899906842709	844424930132011	844424930131976	{"route": "MAN -> VIE", "duration": 2.42}
1125899906842662	844424930131987	844424930131978	{"route": "ZRH -> MUC", "duration": 0.9335458167330677}
1125899906842721	844424930132011	844424930131987	{"route": "MAN -> ZRH", "duration": 1.9638297872340427}
1125899906842688	844424930131974	844424930132008	{"route": "FRA -> SAW", "duration": 3.120697674418605}
1125899906842651	844424930131974	844424930131985	{"route": "FRA -> MIA", "duration": 10.42}
1125899906842654	844424930131978	844424930131998	{"route": "MUC -> AMS", "duration": 1.67}
1125899906842674	844424930131974	844424930131981	{"route": "FRA -> LAS", "duration": 11.75}
1125899906842652	844424930131996	844424930131978	{"route": "OSL -> MUC", "duration": 2.4096969696969697}
1125899906842694	844424930131997	844424930131976	{"route": "ARN -> VIE", "duration": 2.25}
1125899906842671	844424930131987	844424930131977	{"route": "ZRH -> LHR", "duration": 1.867142857142857}
1125899906842703	844424930131986	844424930131974	{"route": "MAD -> FRA", "duration": 2.58}
1125899906842685	844424930132007	844424930131974	{"route": "AGY -> FRA", "duration": 3.204}
1125899906842637	844424930131986	844424930131987	{"route": "MAD -> ZRH", "duration": 2.288657718120805}
1125899906842695	844424930132004	844424930131987	{"route": "BER -> ZRH", "duration": 1.4754696132596685}
1125899906842661	844424930131987	844424930132002	{"route": "ZRH -> DUB", "duration": 2.4171518987341774}
1125899906842704	844424930131994	844424930132010	{"route": "ORD -> NLU", "duration": 4.25}
1125899906842706	844424930131980	844424930132009	{"route": "LAX -> PAE", "duration": 2.9675925925925926}
1125899906842711	844424930131987	844424930132012	{"route": "ZRH -> MRU", "duration": 11.75}
1125899906842719	844424930132010	844424930131994	{"route": "NLU -> ORD", "duration": 4.08}
1125899906842649	844424930131987	844424930131993	{"route": "ZRH -> CDG", "duration": 1.3635889570552147}
1125899906842659	844424930132001	844424930131987	{"route": "FCO -> ZRH", "duration": 1.6115}
1125899906842646	844424930131993	844424930131978	{"route": "CDG -> MUC", "duration": 1.42}
1125899906842750	844424930132017	844424930132000	{"route": "IST -> LOS", "duration": 7.25}
1125899906842785	844424930131978	844424930131980	{"route": "MUC -> LAX", "duration": 12.218607594936708}
1125899906842731	844424930132003	844424930131976	{"route": "PVG -> VIE", "duration": 12.92}
1125899906842730	844424930131994	844424930131976	{"route": "ORD -> VIE", "duration": 8.75}
1125899906842739	844424930131970	844424930131974	{"route": "ATL -> FRA", "duration": 8.75}
1125899906842740	844424930131976	844424930131972	{"route": "VIE -> JFK", "duration": 9.75}
1125899906842869	844424930131980	844424930131974	{"route": "LAX -> FRA", "duration": 10.92}
1125899906842743	844424930131978	844424930131979	{"route": "MUC -> SEA", "duration": 10.67}
1125899906842877	844424930131994	844424930131974	{"route": "ORD -> FRA", "duration": 8.436948529411765}
1125899906842834	844424930131980	844424930131987	{"route": "LAX -> ZRH", "duration": 11.08}
1125899906842889	844424930131974	844424930132021	{"route": "FRA -> NCE", "duration": 1.58}
1125899906842816	844424930131978	844424930132023	{"route": "MUC -> PEK", "duration": 9.916268656716419}
1125899906842769	844424930132001	844424930131994	{"route": "FCO -> ORD", "duration": 10.33}
1125899906842805	844424930131974	844424930132002	{"route": "FRA -> DUB", "duration": 2.17}
1125899906842845	844424930131974	844424930132011	{"route": "FRA -> MAN", "duration": 1.83}
1125899906842782	844424930131972	844424930131976	{"route": "JFK -> VIE", "duration": 8.25}
1125899906842868	844424930131999	844424930131989	{"route": "ONT -> SFO", "duration": 1.5730120481927712}
1125899906842735	844424930131972	844424930131978	{"route": "JFK -> MUC", "duration": 7.5}
1125899906842790	844424930131973	844424930132010	{"route": "MCO -> NLU", "duration": 3.42}
1125899906842823	844424930131974	844424930131982	{"route": "FRA -> ATH", "duration": 2.782039312039312}
1125899906842793	844424930132012	844424930131987	{"route": "MRU -> ZRH", "duration": 12.306666666666667}
1125899906842794	844424930131999	844424930131994	{"route": "ONT -> ORD", "duration": 6.171578947368421}
1125899906842841	844424930131971	844424930131992	{"route": "CLT -> MEX", "duration": 4.441904761904762}
1125899906842798	844424930131983	844424930132010	{"route": "DEN -> NLU", "duration": 3.58}
1125899906842799	844424930132012	844424930132020	{"route": "MRU -> NBO", "duration": 4.255333333333334}
1125899906842802	844424930131980	844424930132010	{"route": "LAX -> NLU", "duration": 3.67}
1125899906842817	844424930131974	844424930132016	{"route": "FRA -> WAW", "duration": 1.7}
1125899906842847	844424930131998	844424930131975	{"route": "AMS -> EWR", "duration": 8.42}
1125899906842851	844424930131980	844424930131971	{"route": "LAX -> CLT", "duration": 4.834755905511811}
1125899906842820	844424930131976	844424930132003	{"route": "VIE -> PVG", "duration": 11.08}
1125899906842821	844424930131978	844424930132002	{"route": "MUC -> DUB", "duration": 2.58}
1125899906842838	844424930132012	844424930131976	{"route": "MRU -> VIE", "duration": 10.83}
1125899906842747	844424930131994	844424930131979	{"route": "ORD -> SEA", "duration": 4.805629213483146}
1125899906842843	844424930131999	844424930131971	{"route": "ONT -> CLT", "duration": 4.925079365079365}
1125899906842844	844424930131974	844424930132012	{"route": "FRA -> MRU", "duration": 11.25}
1125899906842885	844424930131980	844424930131992	{"route": "LAX -> MEX", "duration": 3.7393414211438474}
1125899906842861	844424930132014	844424930132006	{"route": "DEL -> BKK", "duration": 3.9745318352059926}
1125899906842811	844424930131988	844424930131974	{"route": "DFW -> FRA", "duration": 9.83}
1125899906842778	844424930131983	844424930131992	{"route": "DEN -> MEX", "duration": 3.9503149606299215}
1125899906842853	844424930131995	844424930132008	{"route": "CMN -> SAW", "duration": 4.776666666666666}
1125899906842837	844424930131972	844424930131979	{"route": "JFK -> SEA", "duration": 6.481054545454546}
1125899906842864	844424930131992	844424930131971	{"route": "MEX -> CLT", "duration": 3.756746987951807}
1125899906842795	844424930131972	844424930131969	{"route": "JFK -> GRU", "duration": 9.577190265486726}
1125899906842779	844424930131971	844424930131979	{"route": "CLT -> SEA", "duration": 5.923562231759656}
1125899906842871	844424930131970	844424930131989	{"route": "ATL -> SFO", "duration": 5.439145962732919}
1125899906842829	844424930131981	844424930131971	{"route": "LAS -> CLT", "duration": 4.2522370936902485}
1125899906842870	844424930131985	844424930131989	{"route": "MIA -> SFO", "duration": 6.800783410138249}
1125899906842727	844424930131983	844424930131985	{"route": "DEN -> MIA", "duration": 4.126369636963696}
1125899906842796	844424930131979	844424930131992	{"route": "SEA -> MEX", "duration": 5.548095238095238}
1125899906842729	844424930131988	844424930131975	{"route": "DFW -> EWR", "duration": 3.3751395348837208}
1125899906842822	844424930131980	844424930131979	{"route": "LAX -> SEA", "duration": 3.152346368715084}
1125899906842763	844424930131975	844424930131974	{"route": "EWR -> FRA", "duration": 7.4638709677419355}
1125899906842707	844424930131970	844424930131990	{"route": "ATL -> BOG", "duration": 4.67261980830671}
1125899906842678	844424930131988	844424930131990	{"route": "DFW -> BOG", "duration": 5.33}
1125899906842650	844424930131983	844424930131973	{"route": "DEN -> MCO", "duration": 3.9233521923620933}
1125899906842676	844424930131980	844424930131989	{"route": "LAX -> SFO", "duration": 1.5071743625086147}
1125899906842990	844424930131988	844424930131970	{"route": "DFW -> ATL", "duration": 2.175736434108527}
1125899906842698	844424930131983	844424930131971	{"route": "DEN -> CLT", "duration": 3.2414331723027376}
1125899906842679	844424930131970	844424930131994	{"route": "ATL -> ORD", "duration": 2.1612698412698412}
1125899906842699	844424930131983	844424930131970	{"route": "DEN -> ATL", "duration": 2.951178278688525}
1125899906842665	844424930131994	844424930131983	{"route": "ORD -> DEN", "duration": 2.827733333333333}
1125899906842846	844424930131983	844424930131988	{"route": "DEN -> DFW", "duration": 2.0698040693293143}
1125899906842672	844424930131988	844424930131971	{"route": "DFW -> CLT", "duration": 2.542389112903226}
1125899906842668	844424930131970	844424930131972	{"route": "ATL -> JFK", "duration": 2.264617044228695}
1125899906842663	844424930131980	844424930131983	{"route": "LAX -> DEN", "duration": 2.455197869101979}
1125899906842696	844424930131970	844424930131992	{"route": "ATL -> MEX", "duration": 3.8879432624113477}
1125899906842634	844424930131983	844424930131972	{"route": "DEN -> JFK", "duration": 3.75012987012987}
1125899906842670	844424930131981	844424930131972	{"route": "LAS -> JFK", "duration": 5.010150987224158}
1125899906842883	844424930131985	844424930131987	{"route": "MIA -> ZRH", "duration": 9.077272727272728}
1125899906842768	844424930131994	844424930131971	{"route": "ORD -> CLT", "duration": 2.0736345776031433}
1125899906842860	844424930131971	844424930131999	{"route": "CLT -> ONT", "duration": 5.193333333333333}
1125899906842863	844424930131985	844424930132010	{"route": "MIA -> NLU", "duration": 3.42}
1125899906842832	844424930131994	844424930131981	{"route": "ORD -> LAS", "duration": 4.426638418079096}
1125899906842866	844424930131994	844424930132001	{"route": "ORD -> FCO", "duration": 8.92}
1125899906842867	844424930132010	844424930131973	{"route": "NLU -> MCO", "duration": 3.08}
1125899906842808	844424930131985	844424930131979	{"route": "MIA -> SEA", "duration": 6.922873134328358}
1125899906842887	844424930131981	844424930131974	{"route": "LAS -> FRA", "duration": 11}
1125899906842761	844424930131972	844424930131988	{"route": "JFK -> DFW", "duration": 4.228028169014085}
1125899906842879	844424930132003	844424930131987	{"route": "PVG -> ZRH", "duration": 14.33}
1125899906842724	844424930132015	844424930132003	{"route": "DMK -> PVG", "duration": 4.08}
1125899906842850	844424930132014	844424930131987	{"route": "DEL -> ZRH", "duration": 9.08}
1125899906842848	844424930132013	844424930131978	{"route": "HND -> MUC", "duration": 14.682345679012347}
1125899906842767	844424930131991	844424930131987	{"route": "CAI -> ZRH", "duration": 4.17}
1125899906842748	844424930131979	844424930131985	{"route": "SEA -> MIA", "duration": 6.021498257839721}
1125899906842775	844424930131981	844424930131970	{"route": "LAS -> ATL", "duration": 3.9400818833162745}
1125899906842758	844424930131992	844424930131970	{"route": "MEX -> ATL", "duration": 3.4094258373205744}
1125899906842752	844424930131975	844424930131969	{"route": "EWR -> GRU", "duration": 9.5}
1125899906842742	844424930131985	844424930131994	{"route": "MIA -> ORD", "duration": 3.6495719489981786}
1125899906842882	844424930131973	844424930132025	{"route": "MCO -> AVT", "duration": 3.0734475374732333}
1125899906842857	844424930131973	844424930132024	{"route": "MCO -> EKW", "duration": 3.4790070921985814}
1125899906842725	844424930131992	844424930131980	{"route": "MEX -> LAX", "duration": 4.318684210526316}
1125899906842754	844424930131985	844424930131972	{"route": "MIA -> JFK", "duration": 3.0699259259259257}
1125899906842737	844424930131992	844424930131985	{"route": "MEX -> MIA", "duration": 3.2496975425330814}
1125899906842776	844424930131975	844424930131992	{"route": "EWR -> MEX", "duration": 5.656825396825397}
1125899906842836	844424930131973	844424930131988	{"route": "MCO -> DFW", "duration": 3.152}
1125899906842774	844424930131975	844424930131998	{"route": "EWR -> AMS", "duration": 7.17}
1125899906842813	844424930131971	844424930131975	{"route": "CLT -> EWR", "duration": 1.9068852459016392}
1125899906842858	844424930131973	844424930131971	{"route": "MCO -> CLT", "duration": 1.8396258503401361}
1125899906842828	844424930131975	844424930131978	{"route": "EWR -> MUC", "duration": 7.710909090909091}
1125899906842728	844424930131992	844424930131990	{"route": "MEX -> BOG", "duration": 4.5562368815592205}
1125899906842878	844424930131975	844424930132005	{"route": "EWR -> LIS", "duration": 6.58}
1125899906842833	844424930131975	844424930132001	{"route": "EWR -> FCO", "duration": 8.58}
1125899906842773	844424930131989	844424930131999	{"route": "SFO -> ONT", "duration": 1.4945945945945946}
1125899906842784	844424930131989	844424930131987	{"route": "SFO -> ZRH", "duration": 11.08}
1125899906842852	844424930131975	844424930131981	{"route": "EWR -> LAS", "duration": 5.726792452830189}
1125899906842824	844424930131990	844424930131975	{"route": "BOG -> EWR", "duration": 6.032038834951456}
1125899906842880	844424930131979	844424930131988	{"route": "SEA -> DFW", "duration": 3.954143598615917}
1125899906842806	844424930131974	844424930132022	{"route": "FRA -> DMM", "duration": 7.58}
1125899906842826	844424930131969	844424930131973	{"route": "GRU -> MCO", "duration": 9}
1125899906842792	844424930131989	844424930131992	{"route": "SFO -> MEX", "duration": 4.393370786516854}
1125899906842876	844424930131969	844424930131978	{"route": "GRU -> MUC", "duration": 11.58}
1125899906842760	844424930131974	844424930132018	{"route": "FRA -> CPT", "duration": 11.67}
1125899906842886	844424930131974	844424930131983	{"route": "FRA -> DEN", "duration": 10.590909090909092}
1125899906842859	844424930131969	844424930131972	{"route": "GRU -> JFK", "duration": 9.962927927927927}
1125899906842875	844424930131989	844424930131994	{"route": "SFO -> ORD", "duration": 4.354709418837675}
1125899906842788	844424930131989	844424930131983	{"route": "SFO -> DEN", "duration": 2.67262677484787}
1125899906842762	844424930131974	844424930132013	{"route": "FRA -> HND", "duration": 13.014262295081966}
1125899906842766	844424930131974	844424930131991	{"route": "FRA -> CAI", "duration": 4.152243902439024}
1125899906842756	844424930131974	844424930131972	{"route": "FRA -> JFK", "duration": 8.976470588235294}
1125899906842856	844424930131974	844424930131973	{"route": "FRA -> MCO", "duration": 10.75}
1125899906842862	844424930131974	844424930131994	{"route": "FRA -> ORD", "duration": 9.49637037037037}
1125899906842881	844424930131974	844424930131992	{"route": "FRA -> MEX", "duration": 12.33}
1125899906842825	844424930131974	844424930131979	{"route": "FRA -> SEA", "duration": 10.83}
1125899906842872	844424930131978	844424930132011	{"route": "MUC -> MAN", "duration": 2.25}
1125899906842874	844424930131974	844424930131987	{"route": "FRA -> ZRH", "duration": 0.9511591962905719}
1125899906842807	844424930131989	844424930131979	{"route": "SFO -> SEA", "duration": 2.3307137954701442}
1125899906842780	844424930131974	844424930131993	{"route": "FRA -> CDG", "duration": 1.25}
1125899906842770	844424930131974	844424930132004	{"route": "FRA -> BER", "duration": 1.17}
1125899906842787	844424930131978	844424930131997	{"route": "MUC -> ARN", "duration": 2.25}
1125899906842772	844424930131997	844424930132004	{"route": "ARN -> BER", "duration": 1.58}
1125899906842812	844424930131978	844424930131982	{"route": "MUC -> ATH", "duration": 2.457471264367816}
1125899906842789	844424930132005	844424930131986	{"route": "LIS -> MAD", "duration": 1.4109243697478993}
1125899906842830	844424930132011	844424930131978	{"route": "MAN -> MUC", "duration": 1.92}
1125899906842749	844424930131976	844424930131982	{"route": "VIE -> ATH", "duration": 2.1529}
1125899906842746	844424930132004	844424930131976	{"route": "BER -> VIE", "duration": 1.2527881040892193}
1125899906842884	844424930131986	844424930131978	{"route": "MAD -> MUC", "duration": 2.58}
1125899906842814	844424930131997	844424930131996	{"route": "ARN -> OSL", "duration": 1.0262295081967212}
1125899906842744	844424930131997	844424930131987	{"route": "ARN -> ZRH", "duration": 2.4439370078740157}
1125899906842732	844424930132016	844424930131987	{"route": "WAW -> ZRH", "duration": 2.0850704225352112}
1125899906842854	844424930131976	844424930132001	{"route": "VIE -> FCO", "duration": 1.5826666666666667}
1125899906842835	844424930132005	844424930131974	{"route": "LIS -> FRA", "duration": 3.132815315315315}
1125899906842733	844424930132001	844424930131974	{"route": "FCO -> FRA", "duration": 2}
1125899906842759	844424930131982	844424930131978	{"route": "ATH -> MUC", "duration": 2.712528735632184}
1125899906842755	844424930131987	844424930132003	{"route": "ZRH -> PVG", "duration": 12.25}
1125899906842842	844424930131987	844424930132006	{"route": "ZRH -> BKK", "duration": 10.67}
1125899906842745	844424930131987	844424930132014	{"route": "ZRH -> DEL", "duration": 7.75}
1125899906842771	844424930131987	844424930132019	{"route": "ZRH -> SSH", "duration": 5.165}
1125899906842839	844424930131987	844424930131975	{"route": "ZRH -> EWR", "duration": 9.25}
1125899906842753	844424930131987	844424930131972	{"route": "ZRH -> JFK", "duration": 9.335502958579882}
1125899906842804	844424930131987	844424930132001	{"route": "ZRH -> FCO", "duration": 1.5596363636363637}
1125899906842734	844424930131987	844424930132011	{"route": "ZRH -> MAN", "duration": 2.0931382978723403}
1125899906842810	844424930131976	844424930131974	{"route": "VIE -> FRA", "duration": 1.4924919093851132}
1125899906842800	844424930132002	844424930131978	{"route": "DUB -> MUC", "duration": 2.25}
1125899906842801	844424930131987	844424930132021	{"route": "ZRH -> NCE", "duration": 1.196984126984127}
1125899906842827	844424930132002	844424930131987	{"route": "DUB -> ZRH", "duration": 2.17}
1125899906842738	844424930131987	844424930131974	{"route": "ZRH -> FRA", "duration": 1.091679389312977}
1125899906842819	844424930132002	844424930131974	{"route": "DUB -> FRA", "duration": 2}
1125899906842803	844424930131987	844424930132004	{"route": "ZRH -> BER", "duration": 1.4723342541436464}
1125899906842940	844424930131994	844424930131978	{"route": "ORD -> MUC", "duration": 8.459084967320262}
1125899906842902	844424930131988	844424930132010	{"route": "DFW -> NLU", "duration": 2.67}
1125899906843016	844424930131994	844424930131998	{"route": "ORD -> AMS", "duration": 8.42}
1125899906842983	844424930131974	844424930131969	{"route": "FRA -> GRU", "duration": 12}
1125899906843027	844424930131972	844424930131974	{"route": "JFK -> FRA", "duration": 7.693333333333333}
1125899906843014	844424930131994	844424930131977	{"route": "ORD -> LHR", "duration": 8.08}
1125899906842927	844424930131975	844424930131982	{"route": "EWR -> ATH", "duration": 9.5}
1125899906842928	844424930131976	844424930131991	{"route": "VIE -> CAI", "duration": 3.42}
1125899906842901	844424930131978	844424930132014	{"route": "MUC -> DEL", "duration": 7.42}
1125899906842938	844424930131974	844424930132020	{"route": "FRA -> NBO", "duration": 8.5}
1125899906842970	844424930131978	844424930132013	{"route": "MUC -> HND", "duration": 12.5085}
1125899906843002	844424930131974	844424930131986	{"route": "FRA -> MAD", "duration": 2.75}
1125899906842957	844424930131989	844424930131993	{"route": "SFO -> CDG", "duration": 10.75}
1125899906842910	844424930131978	844424930131992	{"route": "MUC -> MEX", "duration": 13}
1125899906842960	844424930131976	844424930132012	{"route": "VIE -> MRU", "duration": 10.25}
1125899906842962	844424930131990	844424930131987	{"route": "BOG -> ZRH", "duration": 12.96}
1125899906842963	844424930132004	844424930132021	{"route": "BER -> NCE", "duration": 2}
1125899906842906	844424930131974	844424930131998	{"route": "FRA -> AMS", "duration": 1.25}
1125899906842967	844424930131994	844424930131999	{"route": "ORD -> ONT", "duration": 8.76}
1125899906842985	844424930132020	844424930131974	{"route": "NBO -> FRA", "duration": 9.08}
1125899906842935	844424930131994	844424930131992	{"route": "ORD -> MEX", "duration": 4.6358}
1125899906842974	844424930131980	844424930132013	{"route": "LAX -> HND", "duration": 12.296713286713286}
1125899906842995	844424930131974	844424930132007	{"route": "FRA -> AGY", "duration": 2.9566666666666666}
1125899906842959	844424930131999	844424930131970	{"route": "ONT -> ATL", "duration": 4.139763033175355}
1125899906842961	844424930131999	844424930131981	{"route": "ONT -> LAS", "duration": 1.1840714285714287}
1125899906843046	844424930131985	844424930131974	{"route": "MIA -> FRA", "duration": 9}
1125899906843011	844424930131980	844424930131969	{"route": "LAX -> GRU", "duration": 11.83}
1125899906843010	844424930132022	844424930132017	{"route": "DMM -> IST", "duration": 4.5}
1125899906843021	844424930131987	844424930131990	{"route": "ZRH -> BOG", "duration": 11.92}
1125899906842988	844424930131974	844424930132001	{"route": "FRA -> FCO", "duration": 1.83}
1125899906843038	844424930132026	844424930131995	{"route": "ALG -> CMN", "duration": 2}
1125899906842954	844424930131972	844424930131987	{"route": "JFK -> ZRH", "duration": 7.709763313609468}
1125899906842947	844424930131981	844424930131992	{"route": "LAS -> MEX", "duration": 3.8039748953974897}
1125899906843051	844424930132010	844424930131983	{"route": "NLU -> DEN", "duration": 3.58}
1125899906842987	844424930132022	844424930131974	{"route": "DMM -> FRA", "duration": 8.5}
1125899906842895	844424930131984	844424930131974	{"route": "DXB -> FRA", "duration": 7.25}
1125899906842920	844424930131984	844424930132004	{"route": "DXB -> BER", "duration": 7}
1125899906842991	844424930132003	844424930132015	{"route": "PVG -> DMK", "duration": 4.765263157894736}
1125899906842921	844424930132006	844424930131978	{"route": "BKK -> MUC", "duration": 12.33}
1125899906842911	844424930132017	844424930131995	{"route": "IST -> CMN", "duration": 5}
1125899906842909	844424930132006	844424930131976	{"route": "BKK -> VIE", "duration": 11.58}
1125899906842981	844424930132023	844424930131978	{"route": "PEK -> MUC", "duration": 11.218148148148147}
1125899906842898	844424930132008	844424930132019	{"route": "SAW -> SSH", "duration": 2.58}
1125899906842976	844424930132013	844424930131979	{"route": "HND -> SEA", "duration": 9.204489795918366}
1125899906843036	844424930132018	844424930131978	{"route": "CPT -> MUC", "duration": 11.25}
1125899906843040	844424930132023	844424930131974	{"route": "PEK -> FRA", "duration": 10.52}
1125899906842942	844424930132018	844424930131987	{"route": "CPT -> ZRH", "duration": 11.5}
1125899906843031	844424930132019	844424930131987	{"route": "SSH -> ZRH", "duration": 4.875}
1125899906842984	844424930132028	844424930131979	{"route": "DAL -> SEA", "duration": 4.506621621621622}
1125899906842950	844424930131970	844424930131999	{"route": "ATL -> ONT", "duration": 4.83555023923445}
1125899906843052	844424930131981	844424930131973	{"route": "LAS -> MCO", "duration": 5.558995215311005}
1125899906842986	844424930131981	844424930132009	{"route": "LAS -> PAE", "duration": 2.8583916083916083}
1125899906843013	844424930131985	844424930131978	{"route": "MIA -> MUC", "duration": 9}
1125899906842972	844424930131980	844424930131985	{"route": "LAX -> MIA", "duration": 4.942163164400494}
1125899906843024	844424930131988	844424930131992	{"route": "DFW -> MEX", "duration": 2.849013282732448}
1125899906843030	844424930131980	844424930131973	{"route": "LAX -> MCO", "duration": 5.466036414565826}
1125899906842946	844424930131992	844424930131983	{"route": "MEX -> DEN", "duration": 3.950793650793651}
1125899906842975	844424930131992	844424930132017	{"route": "MEX -> IST", "duration": 15.909811320754716}
1125899906842908	844424930131980	844424930131975	{"route": "LAX -> EWR", "duration": 5.272758620689655}
1125899906842919	844424930131971	844424930131989	{"route": "CLT -> SFO", "duration": 5.8428125}
1125899906843022	844424930131972	844424930131970	{"route": "JFK -> ATL", "duration": 2.6379726890756303}
1125899906842926	844424930131985	844424930131992	{"route": "MIA -> MEX", "duration": 3.846155303030303}
1125899906843034	844424930131973	844424930131989	{"route": "MCO -> SFO", "duration": 6.515077720207254}
1125899906842952	844424930131992	844424930131979	{"route": "MEX -> SEA", "duration": 6.045662650602409}
1125899906842989	844424930131972	844424930131973	{"route": "JFK -> MCO", "duration": 3.07693246541904}
1125899906842956	844424930131985	844424930131980	{"route": "MIA -> LAX", "duration": 6.171448362720403}
1125899906842922	844424930131981	844424930131975	{"route": "LAS -> EWR", "duration": 4.975751633986928}
1125899906842980	844424930131992	844424930131981	{"route": "MEX -> LAS", "duration": 4.130675105485232}
1125899906842941	844424930131971	844424930131980	{"route": "CLT -> LAX", "duration": 5.491915584415584}
1125899906842918	844424930132024	844424930131973	{"route": "EKW -> MCO", "duration": 3.4636363636363634}
1125899906842930	844424930131981	844424930131989	{"route": "LAS -> SFO", "duration": 1.754177966101695}
1125899906842917	844424930131985	844424930131988	{"route": "MIA -> DFW", "duration": 3.521592356687898}
1125899906842982	844424930132025	844424930131973	{"route": "AVT -> MCO", "duration": 3.143809523809524}
1125899906842897	844424930132010	844424930131990	{"route": "NLU -> BOG", "duration": 4.5}
1125899906843050	844424930131973	844424930131980	{"route": "MCO -> LAX", "duration": 5.9792101341281665}
1125899906842933	844424930131992	844424930131974	{"route": "MEX -> FRA", "duration": 10.67}
1125899906842936	844424930131992	844424930131978	{"route": "MEX -> MUC", "duration": 10.75}
1125899906842955	844424930131992	844424930131972	{"route": "MEX -> JFK", "duration": 4.757277882797732}
1125899906843017	844424930131979	844424930131974	{"route": "SEA -> FRA", "duration": 10.17}
1125899906842964	844424930131973	844424930131972	{"route": "MCO -> JFK", "duration": 2.69}
1125899906843033	844424930131971	844424930131988	{"route": "CLT -> DFW", "duration": 3.050661914460285}
1125899906843001	844424930131971	844424930131985	{"route": "CLT -> MIA", "duration": 2.1816488222698074}
1125899906842900	844424930131992	844424930131989	{"route": "MEX -> SFO", "duration": 5.012112359550562}
1125899906843045	844424930131975	844424930131987	{"route": "EWR -> ZRH", "duration": 7.58}
1125899906843003	844424930131990	844424930131974	{"route": "BOG -> FRA", "duration": 10.42}
1125899906843006	844424930131975	844424930131993	{"route": "EWR -> CDG", "duration": 7.279562043795621}
1125899906842903	844424930131989	844424930131978	{"route": "SFO -> MUC", "duration": 11.12741935483871}
1125899906842949	844424930131975	844424930131979	{"route": "EWR -> SEA", "duration": 6.974187817258883}
1125899906842992	844424930131989	844424930131977	{"route": "SFO -> LHR", "duration": 10.58}
1125899906843028	844424930131969	844424930131987	{"route": "GRU -> ZRH", "duration": 11.227142857142857}
1125899906843055	844424930131975	844424930131977	{"route": "EWR -> LHR", "duration": 7.274791666666666}
1125899906842945	844424930131989	844424930131985	{"route": "SFO -> MIA", "duration": 5.516575}
1125899906843026	844424930131974	844424930131984	{"route": "FRA -> DXB", "duration": 6.42}
1125899906842932	844424930131974	844424930132000	{"route": "FRA -> LOS", "duration": 6.5}
1125899906843007	844424930131990	844424930131972	{"route": "BOG -> JFK", "duration": 5.848}
1125899906842939	844424930131974	844424930132014	{"route": "FRA -> DEL", "duration": 7.8633962264150945}
1125899906842996	844424930131974	844424930132023	{"route": "FRA -> PEK", "duration": 9.386930693069306}
1125899906842977	844424930131989	844424930131975	{"route": "SFO -> EWR", "duration": 5.459810126582279}
1125899906842896	844424930131974	844424930132026	{"route": "FRA -> ALG", "duration": 2.58}
1125899906843041	844424930131990	844424930131992	{"route": "BOG -> MEX", "duration": 4.87160419790105}
1125899906843049	844424930131974	844424930131988	{"route": "FRA -> DFW", "duration": 11.33}
1125899906843020	844424930131974	844424930131980	{"route": "FRA -> LAX", "duration": 11.67}
1125899906842925	844424930131974	844424930131990	{"route": "FRA -> BOG", "duration": 11.5}
1125899906843012	844424930131974	844424930131975	{"route": "FRA -> EWR", "duration": 8.757741935483871}
1125899906843032	844424930131974	844424930132029	{"route": "FRA -> QPP", "duration": 4.418227611940298}
1125899906842943	844424930131978	844424930131975	{"route": "MUC -> EWR", "duration": 9.10421052631579}
1125899906842931	844424930131974	844424930132027	{"route": "FRA -> ZMU", "duration": 3.480660501981506}
1125899906842944	844424930132004	844424930131975	{"route": "BER -> EWR", "duration": 9.33}
1125899906842912	844424930132004	844424930131997	{"route": "BER -> ARN", "duration": 1.6973053892215568}
1125899906842969	844424930131978	844424930132021	{"route": "MUC -> NCE", "duration": 1.5}
1125899906843029	844424930131977	844424930131983	{"route": "LHR -> DEN", "duration": 9.83}
1125899906843043	844424930131978	844424930132016	{"route": "MUC -> WAW", "duration": 1.5685494505494506}
1125899906843053	844424930131974	844424930131977	{"route": "FRA -> LHR", "duration": 1.75}
1125899906842893	844424930131986	844424930131975	{"route": "MAD -> EWR", "duration": 8.92}
1125899906843015	844424930131978	844424930131987	{"route": "MUC -> ZRH", "duration": 0.9354890219560879}
1125899906842923	844424930131974	844424930131976	{"route": "FRA -> VIE", "duration": 1.4051256830601093}
1125899906843019	844424930131977	844424930131989	{"route": "LHR -> SFO", "duration": 11.17}
1125899906842915	844424930132027	844424930131974	{"route": "ZMU -> FRA", "duration": 3.4800411522633743}
1125899906843005	844424930131978	844424930131977	{"route": "MUC -> LHR", "duration": 2.08}
1125899906842979	844424930131996	844424930131987	{"route": "OSL -> ZRH", "duration": 2.595084745762712}
1125899906843025	844424930132005	844424930131975	{"route": "LIS -> EWR", "duration": 8.17}
1125899906842894	844424930131976	844424930131996	{"route": "VIE -> OSL", "duration": 2.33}
1125899906842914	844424930131996	844424930131974	{"route": "OSL -> FRA", "duration": 2.33}
1125899906842998	844424930131977	844424930131975	{"route": "LHR -> EWR", "duration": 8.510205831903946}
1125899906842924	844424930132001	844424930131976	{"route": "FCO -> VIE", "duration": 1.6585925925925926}
1125899906843008	844424930131977	844424930131987	{"route": "LHR -> ZRH", "duration": 1.7962857142857143}
1125899906843039	844424930131976	844424930132021	{"route": "VIE -> NCE", "duration": 1.75}
1125899906843044	844424930131982	844424930131987	{"route": "ATH -> ZRH", "duration": 2.907572016460905}
1125899906842978	844424930131976	844424930131998	{"route": "VIE -> AMS", "duration": 1.92}
1125899906842937	844424930131982	844424930131974	{"route": "ATH -> FRA", "duration": 3.1819174757281554}
1125899906842891	844424930131977	844424930131974	{"route": "LHR -> FRA", "duration": 1.58}
1125899906842892	844424930131987	844424930131984	{"route": "ZRH -> DXB", "duration": 6.194470588235294}
1125899906842993	844424930131987	844424930132018	{"route": "ZRH -> CPT", "duration": 11.459183673469388}
1125899906843054	844424930131976	844424930132016	{"route": "VIE -> WAW", "duration": 1.2515613382899629}
1125899906842916	844424930131987	844424930131989	{"route": "ZRH -> SFO", "duration": 12.17}
1125899906842973	844424930131976	844424930131993	{"route": "VIE -> CDG", "duration": 2.08}
1125899906843035	844424930131987	844424930131985	{"route": "ZRH -> MIA", "duration": 10.742820512820513}
1125899906842890	844424930131987	844424930131969	{"route": "ZRH -> GRU", "duration": 11.964705882352941}
1125899906842965	844424930131976	844424930131987	{"route": "VIE -> ZRH", "duration": 1.3844773790951639}
1125899906843056	844424930132021	844424930131974	{"route": "NCE -> FRA", "duration": 1.67}
1125899906842971	844424930131987	844424930131996	{"route": "ZRH -> OSL", "duration": 2.5}
1125899906843018	844424930131987	844424930131982	{"route": "ZRH -> ATH", "duration": 2.632962962962963}
1125899906843000	844424930131987	844424930131998	{"route": "ZRH -> AMS", "duration": 1.686}
1125899906842929	844424930131993	844424930131975	{"route": "CDG -> EWR", "duration": 8.54820143884892}
1125899906842968	844424930132021	844424930131978	{"route": "NCE -> MUC", "duration": 1.42}
1125899906843042	844424930132021	844424930131987	{"route": "NCE -> ZRH", "duration": 1.2458730158730158}
1125899906842953	844424930131993	844424930131974	{"route": "CDG -> FRA", "duration": 1.33}
1125899906843061	844424930131996	844424930131997	{"route": "OSL -> ARN", "duration": 1.1348979591836734}
1125899906843062	844424930132014	844424930132013	{"route": "DEL -> HND", "duration": 7.5}
1125899906843071	844424930132010	844424930131988	{"route": "NLU -> DFW", "duration": 2.75}
1125899906843108	844424930132010	844424930131980	{"route": "NLU -> LAX", "duration": 3.92}
1125899906843109	844424930131995	844424930131974	{"route": "CMN -> FRA", "duration": 3.58}
1125899906843110	844424930132022	844424930132008	{"route": "DMM -> SAW", "duration": 4.36}
1125899906843148	844424930131974	844424930131970	{"route": "FRA -> ATL", "duration": 10.5}
1125899906842781	844424930131980	844424930131972	{"route": "LAX -> JFK", "duration": 5.46698468786808}
1125899906843100	844424930131984	844424930131987	{"route": "DXB -> ZRH", "duration": 7.25}
1125899906842783	844424930132003	844424930132006	{"route": "PVG -> BKK", "duration": 4.91275}
1125899906843186	844424930132006	844424930131987	{"route": "BKK -> ZRH", "duration": 12.25}
1125899906843166	844424930132003	844424930131974	{"route": "PVG -> FRA", "duration": 13.28718954248366}
1125899906843111	844424930132003	844424930131978	{"route": "PVG -> MUC", "duration": 12.947766990291262}
1125899906843097	844424930132017	844424930132022	{"route": "IST -> DMM", "duration": 4}
1125899906843177	844424930132008	844424930132022	{"route": "SAW -> DMM", "duration": 4.044943820224719}
1125899906843130	844424930132022	844424930131984	{"route": "DMM -> DXB", "duration": 1.4150867052023122}
1125899906843060	844424930132006	844424930132003	{"route": "BKK -> PVG", "duration": 4.337967567567568}
1125899906843093	844424930132008	844424930131995	{"route": "SAW -> CMN", "duration": 5.08}
1125899906843146	844424930132006	844424930131984	{"route": "BKK -> DXB", "duration": 6.932}
1125899906843180	844424930132013	844424930131980	{"route": "HND -> LAX", "duration": 10}
1125899906843133	844424930131988	844424930131969	{"route": "DFW -> GRU", "duration": 10.010574712643677}
1125899906843078	844424930131991	844424930131974	{"route": "CAI -> FRA", "duration": 4.605217391304348}
1125899906843139	844424930131984	844424930132022	{"route": "DXB -> DMM", "duration": 1.5294797687861272}
1125899906843095	844424930131991	844424930131978	{"route": "CAI -> MUC", "duration": 4.08}
1125899906843163	844424930132018	844424930131974	{"route": "CPT -> FRA", "duration": 11.92}
1125899906842751	844424930131988	844424930131994	{"route": "DFW -> ORD", "duration": 2.4338524590163932}
1125899906843094	844424930131970	844424930131969	{"route": "ATL -> GRU", "duration": 9.488674698795181}
1125899906843047	844424930131970	844424930132028	{"route": "ATL -> DAL", "duration": 2.313543956043956}
1125899906843069	844424930132006	844424930132023	{"route": "BKK -> PEK", "duration": 4.598715596330275}
1125899906843173	844424930131983	844424930131978	{"route": "DEN -> MUC", "duration": 9.660873786407768}
1125899906843189	844424930131988	844424930131972	{"route": "DFW -> JFK", "duration": 3.5223887587822014}
1125899906843084	844424930132019	844424930131991	{"route": "SSH -> CAI", "duration": 1.448463687150838}
1125899906843150	844424930132012	844424930131974	{"route": "MRU -> FRA", "duration": 12}
1125899906843176	844424930131983	844424930131974	{"route": "DEN -> FRA", "duration": 9.620671641791045}
1125899906843160	844424930131971	844424930131978	{"route": "CLT -> MUC", "duration": 8.42}
1125899906843144	844424930131970	844424930131981	{"route": "ATL -> LAS", "duration": 4.6118068535825545}
1125899906842818	844424930131970	844424930131988	{"route": "ATL -> DFW", "duration": 2.6761268143621084}
1125899906843138	844424930131973	844424930131969	{"route": "MCO -> GRU", "duration": 8.59185628742515}
1125899906843122	844424930131999	844424930131983	{"route": "ONT -> DEN", "duration": 2.3398709677419354}
1125899906843115	844424930131983	844424930131999	{"route": "DEN -> ONT", "duration": 2.4544039735099337}
1125899906843164	844424930131999	844424930131979	{"route": "ONT -> SEA", "duration": 2.9419338422391856}
1125899906843127	844424930131988	844424930131989	{"route": "DFW -> SFO", "duration": 4.137286486486486}
1125899906843145	844424930131983	844424930131975	{"route": "DEN -> EWR", "duration": 3.694951856946355}
1125899906842899	844424930131983	844424930131980	{"route": "DEN -> LAX", "duration": 2.6262764350453174}
1125899906843132	844424930131983	844424930131994	{"route": "DEN -> ORD", "duration": 2.5679142857142856}
1125899906842958	844424930131981	844424930131988	{"route": "LAS -> DFW", "duration": 2.756236080178174}
1125899906843098	844424930131992	844424930131975	{"route": "MEX -> EWR", "duration": 4.774761904761905}
1125899906843188	844424930132009	844424930131989	{"route": "PAE -> SFO", "duration": 2.213}
1125899906843159	844424930131972	844424930131992	{"route": "JFK -> MEX", "duration": 5.756}
1125899906843143	844424930131983	844424930131989	{"route": "DEN -> SFO", "duration": 2.8512337011033098}
1125899906843136	844424930131981	844424930131999	{"route": "LAS -> ONT", "duration": 1.1342021276595744}
1125899906843156	844424930131994	844424930131985	{"route": "ORD -> MIA", "duration": 3.293823529411765}
1125899906843178	844424930131981	844424930131985	{"route": "LAS -> MIA", "duration": 4.725750577367205}
1125899906843083	844424930131972	844424930131994	{"route": "JFK -> ORD", "duration": 2.9002764227642275}
1125899906843179	844424930131985	844424930131981	{"route": "MIA -> LAS", "duration": 5.691534988713318}
1125899906843113	844424930131972	844424930131971	{"route": "JFK -> CLT", "duration": 2.1983046357615894}
1125899906843066	844424930131994	844424930131988	{"route": "ORD -> DFW", "duration": 2.741755464480874}
1125899906843172	844424930131980	844424930131970	{"route": "LAX -> ATL", "duration": 4.404849420849421}
1125899906843135	844424930131994	844424930131975	{"route": "ORD -> EWR", "duration": 2.2506115357887424}
1125899906843112	844424930131973	844424930131979	{"route": "MCO -> SEA", "duration": 6.617976744186047}
1125899906843183	844424930131992	844424930131973	{"route": "MEX -> MCO", "duration": 3.2190942028985505}
1125899906843157	844424930131985	844424930131983	{"route": "MIA -> DEN", "duration": 4.799933884297521}
1125899906843096	844424930131975	844424930131990	{"route": "EWR -> BOG", "duration": 5.83}
1125899906843057	844424930131985	844424930131973	{"route": "MIA -> MCO", "duration": 2.8003283582089553}
1125899906843187	844424930131973	844424930131983	{"route": "MCO -> DEN", "duration": 4.493834048640916}
1125899906843126	844424930131975	844424930131986	{"route": "EWR -> MAD", "duration": 7.42}
1125899906843184	844424930131971	844424930131983	{"route": "CLT -> DEN", "duration": 3.823534201954397}
1125899906843080	844424930131985	844424930131971	{"route": "MIA -> CLT", "duration": 2.2573982869379017}
1125899906843089	844424930131972	844424930131989	{"route": "JFK -> SFO", "duration": 6.720360544217687}
1125899906843102	844424930131992	844424930131988	{"route": "MEX -> DFW", "duration": 2.7337426900584796}
1125899906843090	844424930131981	844424930131979	{"route": "LAS -> SEA", "duration": 2.9869077306733165}
1125899906843077	844424930131985	844424930131970	{"route": "MIA -> ATL", "duration": 2.108697539797395}
1125899906843073	844424930131979	844424930131975	{"route": "SEA -> EWR", "duration": 5.6236675461741426}
1125899906843120	844424930131979	844424930131972	{"route": "SEA -> JFK", "duration": 5.393210332103321}
1125899906843107	844424930131973	844424930131994	{"route": "MCO -> ORD", "duration": 3.107388535031847}
1125899906843101	844424930131990	844424930131994	{"route": "BOG -> ORD", "duration": 6.25}
1125899906843134	844424930131990	844424930132010	{"route": "BOG -> NLU", "duration": 4.83}
1125899906843059	844424930131975	844424930131988	{"route": "EWR -> DFW", "duration": 4.256245654692932}
1125899906843170	844424930131989	844424930131970	{"route": "SFO -> ATL", "duration": 4.891411589895988}
1125899906843081	844424930131975	844424930131980	{"route": "EWR -> LAX", "duration": 6.219893514036786}
1125899906843064	844424930131979	844424930131981	{"route": "SEA -> LAS", "duration": 2.760527638190955}
1125899906843105	844424930131975	844424930131971	{"route": "EWR -> CLT", "duration": 2.1245081967213113}
1125899906843117	844424930131975	844424930131989	{"route": "EWR -> SFO", "duration": 6.419314345991562}
1125899906843068	844424930131969	844424930131994	{"route": "GRU -> ORD", "duration": 10.67}
1125899906843125	844424930131975	844424930131985	{"route": "EWR -> MIA", "duration": 3.286203451407811}
1125899906843119	844424930131969	844424930131975	{"route": "GRU -> EWR", "duration": 9.83}
1125899906843092	844424930131975	844424930131994	{"route": "EWR -> ORD", "duration": 2.6706201550387596}
1125899906843154	844424930131969	844424930131974	{"route": "GRU -> FRA", "duration": 11.5}
1125899906843169	844424930131978	844424930132018	{"route": "MUC -> CPT", "duration": 11.25}
1125899906843065	844424930131974	844424930131989	{"route": "FRA -> SFO", "duration": 11.603553299492386}
1125899906843088	844424930131978	844424930131983	{"route": "MUC -> DEN", "duration": 10.75}
1125899906843063	844424930131978	844424930131972	{"route": "MUC -> JFK", "duration": 8.83}
1125899906843129	844424930131969	844424930131985	{"route": "GRU -> MIA", "duration": 8.425527210884354}
1125899906843167	844424930131978	844424930131985	{"route": "MUC -> MIA", "duration": 11.08}
1125899906843091	844424930131974	844424930132017	{"route": "FRA -> IST", "duration": 3.1270146137787056}
1125899906843075	844424930131974	844424930131997	{"route": "FRA -> ARN", "duration": 2.17}
1125899906843168	844424930131989	844424930131972	{"route": "SFO -> JFK", "duration": 5.574578729281768}
1125899906843174	844424930131989	844424930131980	{"route": "SFO -> LAX", "duration": 1.5397391304347825}
1125899906843165	844424930131978	844424930131971	{"route": "MUC -> CLT", "duration": 10}
1125899906843118	844424930131978	844424930131969	{"route": "MUC -> GRU", "duration": 12.5}
1125899906843131	844424930132001	844424930131975	{"route": "FCO -> EWR", "duration": 10.25}
1125899906843106	844424930132005	844424930131987	{"route": "LIS -> ZRH", "duration": 2.802446808510638}
1125899906843114	844424930131978	844424930132004	{"route": "MUC -> BER", "duration": 1.17}
1125899906843162	844424930131998	844424930131987	{"route": "AMS -> ZRH", "duration": 1.4702588235294118}
1125899906843082	844424930131998	844424930131978	{"route": "AMS -> MUC", "duration": 1.33}
1125899906843124	844424930131982	844424930131976	{"route": "ATH -> VIE", "duration": 2.3148}
1125899906843074	844424930132011	844424930131974	{"route": "MAN -> FRA", "duration": 1.75}
1125899906843158	844424930131976	844424930132011	{"route": "VIE -> MAN", "duration": 2.58}
1125899906843076	844424930131987	844424930131997	{"route": "ZRH -> ARN", "duration": 2.449291338582677}
1125899906843116	844424930132016	844424930131974	{"route": "WAW -> FRA", "duration": 1.9694573643410853}
1125899906843085	844424930132016	844424930131978	{"route": "WAW -> MUC", "duration": 1.6971929824561405}
1125899906843153	844424930131987	844424930132016	{"route": "ZRH -> WAW", "duration": 1.8959154929577464}
1125899906843072	844424930132021	844424930131976	{"route": "NCE -> VIE", "duration": 1.67}
1125899906843079	844424930131993	844424930131994	{"route": "CDG -> ORD", "duration": 9.17}
1125899906843171	844424930131993	844424930131976	{"route": "CDG -> VIE", "duration": 1.92}
1125899906843215	844424930131994	844424930131987	{"route": "ORD -> ZRH", "duration": 8.67}
1125899906842913	844424930131970	844424930131983	{"route": "ATL -> DEN", "duration": 3.486002044989775}
1125899906842815	844424930131980	844424930131981	{"route": "LAX -> LAS", "duration": 1.2583942558746737}
1125899906843195	844424930131980	844424930131978	{"route": "LAX -> MUC", "duration": 11.219}
1125899906843224	844424930131980	844424930131977	{"route": "LAX -> LHR", "duration": 10.5}
1125899906843227	844424930131970	844424930131980	{"route": "ATL -> LAX", "duration": 5.118298387096774}
1125899906843211	844424930131974	844424930131978	{"route": "FRA -> MUC", "duration": 0.92}
1125899906843207	844424930131974	844424930131996	{"route": "FRA -> OSL", "duration": 2.08}
1125899906843226	844424930131978	844424930131991	{"route": "MUC -> CAI", "duration": 3.700222222222222}
1125899906843200	844424930131978	844424930131989	{"route": "MUC -> SFO", "duration": 11.960774193548387}
1125899906843212	844424930131978	844424930131996	{"route": "MUC -> OSL", "duration": 2.33}
1125899906843217	844424930132004	844424930131984	{"route": "BER -> DXB", "duration": 6.33}
1125899906843214	844424930131985	844424930131975	{"route": "MIA -> EWR", "duration": 3.1984642857142855}
1125899906843196	844424930132017	844424930132003	{"route": "IST -> PVG", "duration": 10.375}
1125899906843197	844424930132021	844424930132004	{"route": "NCE -> BER", "duration": 2}
1125899906843198	844424930132010	844424930131985	{"route": "NLU -> MIA", "duration": 3.08}
1125899906843193	844424930131998	844424930131976	{"route": "AMS -> VIE", "duration": 1.83}
1125899906843204	844424930132009	844424930131980	{"route": "PAE -> LAX", "duration": 2.824375}
1125899906843221	844424930131997	844424930131978	{"route": "ARN -> MUC", "duration": 2.25}
1125899906843213	844424930131976	844424930131978	{"route": "VIE -> MUC", "duration": 1.0012083333333333}
1125899906843220	844424930131993	844424930131989	{"route": "CDG -> SFO", "duration": 11.42}
1125899906843209	844424930131976	844424930131977	{"route": "VIE -> LHR", "duration": 2.4452506596306067}
1125899906843201	844424930131987	844424930131980	{"route": "ZRH -> LAX", "duration": 12.33}
1125899906843205	844424930131987	844424930132005	{"route": "ZRH -> LIS", "duration": 2.988829787234043}
1125899906843223	844424930131971	844424930131973	{"route": "CLT -> MCO", "duration": 1.7809213863060016}
1125899906843216	844424930131992	844424930131994	{"route": "MEX -> ORD", "duration": 4.2098876404494385}
1125899906843202	844424930131970	844424930131973	{"route": "ATL -> MCO", "duration": 1.533030303030303}
1125899906843192	844424930132028	844424930131970	{"route": "DAL -> ATL", "duration": 2.0110103626943006}
1125899906843219	844424930131979	844424930131970	{"route": "SEA -> ATL", "duration": 4.806286149162862}
1125899906842741	844424930131988	844424930131999	{"route": "DFW -> ONT", "duration": 3.3857714285714287}
1125899906842904	844424930131988	844424930131980	{"route": "DFW -> LAX", "duration": 3.507873303167421}
1125899906843222	844424930131979	844424930131994	{"route": "SEA -> ORD", "duration": 4.407633262260128}
1125899906843208	844424930131979	844424930132028	{"route": "SEA -> DAL", "duration": 3.9535616438356165}
1125899906843225	844424930131979	844424930131999	{"route": "SEA -> ONT", "duration": 2.641942028985507}
1125899906843206	844424930131969	844424930131988	{"route": "GRU -> DFW", "duration": 10.481904761904762}
1125899906843218	844424930131969	844424930131992	{"route": "GRU -> MEX", "duration": 9.308181818181819}
1125899906843191	844424930131988	844424930131985	{"route": "DFW -> MIA", "duration": 2.901918918918919}
1125899906842865	844424930131983	844424930131981	{"route": "DEN -> LAS", "duration": 2.1104979253112033}
\.


--
-- Data for Name: _ag_label_edge; Type: TABLE DATA; Schema: flight_routes; Owner: dst_graph_designer
--

COPY flight_routes._ag_label_edge (id, start_id, end_id, properties) FROM stdin;
\.


--
-- Data for Name: _ag_label_vertex; Type: TABLE DATA; Schema: flight_routes; Owner: dst_graph_designer
--

COPY flight_routes._ag_label_vertex (id, properties) FROM stdin;
\.


--
-- Data for Name: scheduled_routes; Type: TABLE DATA; Schema: l3; Owner: dst_graph_designer
--

COPY l3.scheduled_routes (departure_airport_code, arrival_airport_code, avg_flight_duration_hours) FROM stdin;
\.


--
-- Data for Name: scheduled_routes; Type: TABLE DATA; Schema: public; Owner: dst_graph_designer
--

COPY public.scheduled_routes (departure_airport_code, arrival_airport_code, avg_flight_duration_hours) FROM stdin;
JFK	DEN	4.7167705382436261
AMS	EWR	8.4200000000000000
MIA	NLU	3.4200000000000000
LAS	FRA	11.0000000000000000
QPP	FRA	4.4518635170603675
MCO	ATL	1.6548051118210863
BER	FRA	1.2500000000000000
MCO	EWR	2.7591180048661800
SEA	SFO	2.3011141868512111
DEN	LHR	9.0800000000000000
AMS	FRA	1.1700000000000000
LHR	ORD	9.4200000000000000
MCO	MIA	2.7197974683544304
MUC	PVG	11.4335294117647059
EWR	ATL	2.5515800561797753
EWR	MCO	3.0793438639125152
EWR	BER	8.0800000000000000
MCO	BOG	3.9903347280334728
SFO	LAS	1.8336498761354253
MUC	BKK	10.5000000000000000
PAE	LAS	2.5427857142857143
BOG	ATL	5.1445751633986928
SEA	CLT	5.0024892703862661
CDG	ZRH	1.3111963190184049
ZRH	CAI	4.0020481927710843
CLT	ATL	1.3937907949790795
LHR	VIE	2.2324802110817942
MAN	VIE	2.4200000000000000
MAN	ZRH	1.9638297872340426
FRA	SAW	3.1206976744186047
ARN	VIE	2.2500000000000000
MAD	FRA	2.5800000000000000
BER	ZRH	1.4754696132596685
ORD	NLU	4.2500000000000000
LAX	PAE	2.9675925925925926
ZRH	MRU	11.7500000000000000
NLU	ORD	4.0800000000000000
IST	LOS	7.2500000000000000
MUC	LAX	12.2186075949367089
PVG	VIE	12.9200000000000000
ORD	VIE	8.7500000000000000
ATL	FRA	8.7500000000000000
VIE	JFK	9.7500000000000000
LAX	FRA	10.9200000000000000
MUC	SEA	10.6700000000000000
ORD	FRA	8.4369485294117647
LAX	ZRH	11.0800000000000000
FRA	NCE	1.5800000000000000
MUC	PEK	9.9162686567164179
FCO	ORD	10.3300000000000000
FRA	DUB	2.1700000000000000
FRA	MAN	1.8300000000000000
JFK	VIE	8.2500000000000000
ONT	SFO	1.5730120481927711
JFK	MUC	7.5000000000000000
MCO	NLU	3.4200000000000000
FRA	ATH	2.7820393120393120
MRU	ZRH	12.3066666666666667
ONT	ORD	6.1715789473684211
CLT	MEX	4.4419047619047619
DEN	NLU	3.5800000000000000
LAX	CLT	4.8347559055118110
VIE	PVG	11.0800000000000000
MUC	DUB	2.5800000000000000
MRU	VIE	10.8300000000000000
ORD	SEA	4.8056292134831461
ONT	CLT	4.9250793650793651
FRA	MRU	11.2500000000000000
LAX	MEX	3.7393414211438475
MIA	ZRH	9.0772727272727273
ORD	CLT	2.0736345776031434
CLT	ONT	5.1933333333333333
ORD	LAS	4.4266384180790960
ORD	FCO	8.9200000000000000
NLU	MCO	3.0800000000000000
MIA	SEA	6.9228731343283582
JFK	DFW	4.2280281690140845
PVG	ZRH	14.3300000000000000
BKK	DEL	4.6048434925864909
ORD	ATL	2.0775648535564854
GRU	ATL	9.9334146341463415
ATL	MIA	1.9981752873563218
DFW	DEN	2.2172720478325859
DEN	SEA	3.3814365671641791
DXB	BKK	6.0840000000000000
ORD	MCO	2.9216180371352785
IST	FRA	3.3772406639004149
ATL	CLT	1.2751778329197684
DFW	LAS	3.0950502706883217
DXB	DEL	3.2190769230769231
PEK	BKK	5.3227249357326478
LAX	DFW	3.0984633757961783
ATL	EWR	2.2232052161976664
DFW	MCO	2.6608726003490401
CLT	JFK	1.9648586810228802
DXB	MUC	6.7500000000000000
ATL	SEA	5.7509759759759760
SAW	FRA	3.3775328947368421
ONT	DFW	2.9705949656750572
DFW	SEA	4.5001123595505618
HND	FRA	14.6746558704453441
DEL	MUC	8.9200000000000000
CMN	IST	4.5705769230769231
LOS	FRA	6.5800000000000000
ATL	BOG	4.6726198083067093
DFW	BOG	5.3300000000000000
DEN	MCO	3.9233521923620934
LAX	SFO	1.5071743625086147
CLT	LAS	5.0239038461538462
BOG	MIA	3.9478876404494382
MEX	GRU	9.5787500000000000
DFW	ATL	2.1757364341085271
DEN	CLT	3.2414331723027375
ATL	ORD	2.1612698412698413
DEN	ATL	2.9511782786885246
ORD	DEN	2.8277333333333333
DEN	DFW	2.0698040693293142
DFW	CLT	2.5423891129032258
ATL	JFK	2.2646170442286947
LAX	DEN	2.4551978691019787
ATL	MEX	3.8879432624113475
DEN	JFK	3.7501298701298701
LAX	ORD	4.1538231292517007
EWR	VIE	8.0982142857142857
ORD	LAX	4.6343263371699391
MCO	FRA	9.0800000000000000
MIA	GRU	8.3207275803722504
ORD	JFK	2.3604174228675136
ORD	GRU	10.2500000000000000
ORD	CDG	8.0800000000000000
SEA	LAX	2.9741778127458694
ATH	EWR	11.1700000000000000
MUC	DXB	5.8300000000000000
CAI	VIE	3.7500000000000000
LHR	MUC	1.8300000000000000
MCO	LAS	6.4651792828685259
SFO	DFW	3.5886527929901424
MAD	ZRH	2.2886577181208054
MRU	NBO	4.2553333333333333
LAX	NLU	3.6700000000000000
FRA	WAW	1.7000000000000000
MCO	LAX	5.9792101341281669
MEX	FRA	10.6700000000000000
FRA	DFW	11.3300000000000000
FRA	LAX	11.6700000000000000
FRA	BOG	11.5000000000000000
FRA	EWR	8.7577419354838710
FRA	QPP	4.4182276119402985
MUC	NCE	1.5000000000000000
LHR	DEN	9.8300000000000000
MUC	WAW	1.5685494505494505
FRA	LHR	1.7500000000000000
LHR	SFO	11.1700000000000000
ZMU	FRA	3.4800411522633745
MUC	LHR	2.0800000000000000
CDG	ORD	9.1700000000000000
CDG	VIE	1.9200000000000000
ZRH	VIE	1.3433385335413417
MIA	BOG	3.7066156202143951
DMK	PVG	4.0800000000000000
DEL	ZRH	9.0800000000000000
HND	MUC	14.6823456790123457
CAI	ZRH	4.1700000000000000
DEL	BKK	3.9745318352059925
DFW	FRA	9.8300000000000000
DEN	MEX	3.9503149606299213
CMN	SAW	4.7766666666666667
JFK	SEA	6.4810545454545455
MEX	CLT	3.7567469879518072
JFK	GRU	9.5771902654867257
CLT	SEA	5.9235622317596567
ATL	SFO	5.4391459627329193
LAS	CLT	4.2522370936902486
MIA	SFO	6.8007834101382488
DEN	MIA	4.1263696369636964
SEA	MEX	5.5480952380952381
DFW	EWR	3.3751395348837209
LAX	SEA	3.1523463687150838
EWR	FRA	7.4638709677419355
SEA	MIA	6.0214982578397213
LAS	ATL	3.9400818833162743
MEX	ATL	3.4094258373205742
EWR	GRU	9.5000000000000000
MIA	ORD	3.6495719489981785
MCO	AVT	3.0734475374732334
MCO	EKW	3.4790070921985816
MEX	LAX	4.3186842105263158
MIA	JFK	3.0699259259259259
MEX	MIA	3.2496975425330813
EWR	MEX	5.6568253968253968
MCO	DFW	3.1520000000000000
EWR	AMS	7.1700000000000000
CLT	EWR	1.9068852459016393
MCO	CLT	1.8396258503401361
EWR	MUC	7.7109090909090909
MEX	BOG	4.5562368815592204
EWR	LIS	6.5800000000000000
EWR	FCO	8.5800000000000000
SFO	ONT	1.4945945945945946
SFO	ZRH	11.0800000000000000
EWR	LAS	5.7267924528301887
BOG	EWR	6.0320388349514563
SEA	DFW	3.9541435986159170
FRA	DMM	7.5800000000000000
GRU	MCO	9.0000000000000000
SFO	MEX	4.3933707865168539
GRU	MUC	11.5800000000000000
FRA	CPT	11.6700000000000000
FRA	DEN	10.5909090909090909
GRU	JFK	9.9629279279279279
SFO	ORD	4.3547094188376754
SFO	DEN	2.6726267748478702
FRA	HND	13.0142622950819672
FRA	CAI	4.1522439024390244
FRA	JFK	8.9764705882352941
FRA	MCO	10.7500000000000000
FRA	ORD	9.4963703703703704
FRA	MEX	12.3300000000000000
FRA	SEA	10.8300000000000000
MUC	MAN	2.2500000000000000
FRA	ZRH	0.95115919629057187017
SFO	SEA	2.3307137954701441
FRA	CDG	1.2500000000000000
FRA	BER	1.1700000000000000
MUC	ARN	2.2500000000000000
ARN	BER	1.5800000000000000
MUC	ATH	2.4574712643678161
LIS	MAD	1.4109243697478992
MAN	MUC	1.9200000000000000
VIE	ATH	2.1529000000000000
BER	VIE	1.2527881040892193
MAD	MUC	2.5800000000000000
ARN	OSL	1.0262295081967213
ARN	ZRH	2.4439370078740157
WAW	ZRH	2.0850704225352113
VIE	FCO	1.5826666666666667
LIS	FRA	3.1328153153153153
FCO	FRA	2.0000000000000000
ATH	MUC	2.7125287356321839
ZRH	PVG	12.2500000000000000
ZRH	BKK	10.6700000000000000
ZRH	DEL	7.7500000000000000
ZRH	SSH	5.1650000000000000
ZRH	EWR	9.2500000000000000
ZRH	JFK	9.3355029585798817
ZRH	FCO	1.5596363636363636
ZRH	MAN	2.0931382978723404
VIE	FRA	1.4924919093851133
DUB	MUC	2.2500000000000000
ZRH	NCE	1.1969841269841270
DUB	ZRH	2.1700000000000000
ZRH	FRA	1.0916793893129771
DUB	FRA	2.0000000000000000
ZRH	BER	1.4723342541436464
ORD	MUC	8.4590849673202614
DFW	NLU	2.6700000000000000
ORD	AMS	8.4200000000000000
FRA	GRU	12.0000000000000000
JFK	FRA	7.6933333333333333
ORD	LHR	8.0800000000000000
EWR	ATH	9.5000000000000000
VIE	CAI	3.4200000000000000
MUC	DEL	7.4200000000000000
FRA	NBO	8.5000000000000000
MUC	HND	12.5085000000000000
FRA	MAD	2.7500000000000000
SFO	CDG	10.7500000000000000
MUC	MEX	13.0000000000000000
VIE	MRU	10.2500000000000000
BOG	ZRH	12.9600000000000000
BER	NCE	2.0000000000000000
FRA	AMS	1.2500000000000000
ORD	ONT	8.7600000000000000
NBO	FRA	9.0800000000000000
ORD	MEX	4.6358000000000000
LAX	HND	12.2967132867132867
FRA	AGY	2.9566666666666667
ONT	ATL	4.1397630331753555
ONT	LAS	1.1840714285714286
MIA	FRA	9.0000000000000000
LAX	GRU	11.8300000000000000
DMM	IST	4.5000000000000000
ZRH	BOG	11.9200000000000000
FRA	FCO	1.8300000000000000
ALG	CMN	2.0000000000000000
JFK	ZRH	7.7097633136094675
LAS	MEX	3.8039748953974895
NLU	DEN	3.5800000000000000
DMM	FRA	8.5000000000000000
DXB	FRA	7.2500000000000000
DXB	BER	7.0000000000000000
PVG	DMK	4.7652631578947368
BKK	MUC	12.3300000000000000
IST	CMN	5.0000000000000000
BKK	VIE	11.5800000000000000
PEK	MUC	11.2181481481481481
SAW	SSH	2.5800000000000000
HND	SEA	9.2044897959183673
CPT	MUC	11.2500000000000000
PEK	FRA	10.5200000000000000
CPT	ZRH	11.5000000000000000
SSH	ZRH	4.8750000000000000
DAL	SEA	4.5066216216216216
ATL	ONT	4.8355502392344498
LAS	MCO	5.5589952153110048
LAS	PAE	2.8583916083916084
MIA	MUC	9.0000000000000000
LAX	MIA	4.9421631644004944
DFW	MEX	2.8490132827324478
LAX	MCO	5.4660364145658263
MEX	DEN	3.9507936507936508
MEX	IST	15.9098113207547170
LAX	EWR	5.2727586206896552
CLT	SFO	5.8428125000000000
JFK	ATL	2.6379726890756303
MIA	MEX	3.8461553030303030
MCO	SFO	6.5150777202072539
MEX	SEA	6.0456626506024096
JFK	MCO	3.0769324654190399
JFK	LAX	6.3740223792697291
JFK	LAS	5.9956438969764838
LAS	LAX	1.3324413145539906
VIE	BKK	10.0800000000000000
VIE	ORD	10.1700000000000000
FRA	LIS	3.2202283105022831
LAS	ORD	3.8160390243902439
MCO	MEX	3.9294927536231884
BOG	MCO	4.2712133891213389
JFK	MIA	3.3304619124797407
LAS	JFK	5.0101509872241580
LAS	DEN	2.0029906542056075
VIE	EWR	9.7500000000000000
GRU	LAX	12.3300000000000000
SFO	CLT	5.0898637602179837
MUC	ORD	9.7884210526315789
FRA	PVG	11.4694039735099338
VIE	BER	1.2523420074349442
VIE	ARN	2.2500000000000000
JFK	BOG	5.8960000000000000
ZRH	ORD	10.0800000000000000
FRA	CMN	3.7500000000000000
SEA	MUC	10.0800000000000000
MUC	FRA	1.0800000000000000
ZRH	MUC	0.93354581673306772908
FRA	MIA	10.4200000000000000
MUC	AMS	1.6700000000000000
FRA	LAS	11.7500000000000000
OSL	MUC	2.4096969696969697
ZRH	LHR	1.8671428571428571
AGY	FRA	3.2040000000000000
ZRH	DUB	2.4171518987341772
ZRH	CDG	1.3635889570552147
FCO	ZRH	1.6115000000000000
CDG	MUC	1.4200000000000000
MIA	LAX	6.1714483627204030
LAS	EWR	4.9757516339869281
MEX	LAS	4.1306751054852321
CLT	LAX	5.4919155844155844
EKW	MCO	3.4636363636363636
LAS	SFO	1.7541779661016949
MIA	DFW	3.5215923566878981
AVT	MCO	3.1438095238095238
NLU	BOG	4.5000000000000000
MEX	MUC	10.7500000000000000
MEX	JFK	4.7572778827977316
SEA	FRA	10.1700000000000000
MCO	JFK	2.6900000000000000
CLT	DFW	3.0506619144602851
CLT	MIA	2.1816488222698073
MEX	SFO	5.0121123595505618
EWR	ZRH	7.5800000000000000
BOG	FRA	10.4200000000000000
EWR	CDG	7.2795620437956204
SFO	MUC	11.1274193548387097
EWR	SEA	6.9741878172588832
SFO	LHR	10.5800000000000000
GRU	ZRH	11.2271428571428571
EWR	LHR	7.2747916666666667
SFO	MIA	5.5165750000000000
FRA	DXB	6.4200000000000000
FRA	LOS	6.5000000000000000
BOG	JFK	5.8480000000000000
FRA	DEL	7.8633962264150943
FRA	PEK	9.3869306930693069
SFO	EWR	5.4598101265822785
FRA	ALG	2.5800000000000000
BOG	MEX	4.8716041979010495
MUC	EWR	9.1042105263157895
FRA	ZMU	3.4806605019815059
BER	EWR	9.3300000000000000
BER	ARN	1.6973053892215569
MAD	EWR	8.9200000000000000
MUC	ZRH	0.93548902195608782435
FRA	VIE	1.4051256830601093
OSL	ZRH	2.5950847457627119
LIS	EWR	8.1700000000000000
VIE	OSL	2.3300000000000000
OSL	FRA	2.3300000000000000
LHR	EWR	8.5102058319039451
FCO	VIE	1.6585925925925926
LHR	ZRH	1.7962857142857143
VIE	NCE	1.7500000000000000
ATH	ZRH	2.9075720164609053
VIE	AMS	1.9200000000000000
ATH	FRA	3.1819174757281553
LHR	FRA	1.5800000000000000
ZRH	DXB	6.1944705882352941
ZRH	CPT	11.4591836734693878
VIE	WAW	1.2515613382899628
ZRH	SFO	12.1700000000000000
VIE	CDG	2.0800000000000000
ZRH	MIA	10.7428205128205128
ZRH	GRU	11.9647058823529412
VIE	ZRH	1.3844773790951638
NCE	FRA	1.6700000000000000
ZRH	OSL	2.5000000000000000
ZRH	ATH	2.6329629629629630
ZRH	AMS	1.6860000000000000
CDG	EWR	8.5482014388489209
NCE	MUC	1.4200000000000000
NCE	ZRH	1.2458730158730159
CDG	FRA	1.3300000000000000
OSL	ARN	1.1348979591836735
DEL	HND	7.5000000000000000
NLU	DFW	2.7500000000000000
NLU	LAX	3.9200000000000000
CMN	FRA	3.5800000000000000
DMM	SAW	4.3600000000000000
FRA	ATL	10.5000000000000000
LAX	JFK	5.4669846878680801
DXB	ZRH	7.2500000000000000
PVG	BKK	4.9127500000000000
BKK	ZRH	12.2500000000000000
PVG	FRA	13.2871895424836601
PVG	MUC	12.9477669902912621
IST	DMM	4.0000000000000000
SAW	DMM	4.0449438202247191
DMM	DXB	1.4150867052023121
BKK	PVG	4.3379675675675676
SAW	CMN	5.0800000000000000
BKK	DXB	6.9320000000000000
HND	LAX	10.0000000000000000
DFW	GRU	10.0105747126436782
CAI	FRA	4.6052173913043478
DXB	DMM	1.5294797687861272
CLT	MUC	8.4200000000000000
MCO	GRU	8.5918562874251497
LAS	DFW	2.7562360801781737
MEX	EWR	4.7747619047619048
PAE	SFO	2.2130000000000000
JFK	MEX	5.7560000000000000
LAS	ONT	1.1342021276595745
LAS	MIA	4.7257505773672055
JFK	ORD	2.9002764227642276
MIA	LAS	5.6915349887133183
JFK	CLT	2.1983046357615894
MCO	SEA	6.6179767441860465
MEX	MCO	3.2190942028985507
MIA	DEN	4.7999338842975207
EWR	BOG	5.8300000000000000
MIA	MCO	2.8003283582089552
MCO	DEN	4.4938340486409156
EWR	MAD	7.4200000000000000
CLT	DEN	3.8235342019543974
MIA	CLT	2.2573982869379015
JFK	SFO	6.7203605442176871
MEX	DFW	2.7337426900584795
LAS	SEA	2.9869077306733167
MIA	ATL	2.1086975397973951
SEA	EWR	5.6236675461741425
SEA	JFK	5.3932103321033210
MCO	ORD	3.1073885350318471
SEA	MCO	5.6726351351351351
EWR	DUB	6.7500000000000000
CLT	ORD	2.2244642857142857
SFO	PAE	2.2594202898550725
BOG	DFW	5.9138554216867470
SFO	MCO	5.3632697547683924
SFO	FRA	10.9817857142857143
SEA	DEN	2.7308835341365462
EWR	DEN	4.4413370473537604
BOG	ORD	6.2500000000000000
BOG	NLU	4.8300000000000000
EWR	DFW	4.2562456546929316
SFO	ATL	4.8914115898959881
EWR	LAX	6.2198935140367861
SEA	LAS	2.7605276381909548
EWR	CLT	2.1245081967213115
EWR	SFO	6.4193143459915612
GRU	ORD	10.6700000000000000
EWR	MIA	3.2862034514078111
GRU	EWR	9.8300000000000000
EWR	ORD	2.6706201550387597
GRU	FRA	11.5000000000000000
MUC	CPT	11.2500000000000000
FRA	SFO	11.6035532994923858
MUC	DEN	10.7500000000000000
MUC	JFK	8.8300000000000000
GRU	MIA	8.4255272108843537
MUC	MIA	11.0800000000000000
FRA	IST	3.1270146137787056
FRA	ARN	2.1700000000000000
SFO	JFK	5.5745787292817680
SFO	LAX	1.5397391304347826
MUC	CLT	10.0000000000000000
MUC	GRU	12.5000000000000000
AMS	ORD	9.4200000000000000
LHR	LAX	11.3300000000000000
MUC	MAD	2.7500000000000000
OSL	VIE	2.3300000000000000
MUC	FCO	1.5000000000000000
MUC	LIS	3.3300000000000000
MUC	CDG	1.6700000000000000
MUC	VIE	1.0532083333333333
FCO	EWR	10.2500000000000000
LIS	ZRH	2.8024468085106383
MUC	BER	1.1700000000000000
AMS	ZRH	1.4702588235294118
AMS	MUC	1.3300000000000000
ATH	VIE	2.3148000000000000
MAN	FRA	1.7500000000000000
VIE	MAN	2.5800000000000000
BER	MUC	1.1700000000000000
ARN	FRA	2.2500000000000000
LIS	MUC	3.1816962025316456
DUB	EWR	7.8300000000000000
FCO	MUC	1.5800000000000000
ZRH	MAD	2.4200000000000000
WAW	VIE	1.3318587360594796
ZRH	ARN	2.4492913385826772
WAW	FRA	1.9694573643410853
WAW	MUC	1.6971929824561404
ZRH	WAW	1.8959154929577465
NCE	VIE	1.6700000000000000
ATL	LAS	4.6118068535825545
ATL	DFW	2.6761268143621085
ONT	DEN	2.3398709677419355
DEN	ONT	2.4544039735099338
ONT	SEA	2.9419338422391858
DFW	SFO	4.1372864864864865
DEN	EWR	3.6949518569463549
DEN	LAX	2.6262764350453172
DEN	ORD	2.5679142857142857
DEN	SFO	2.8512337011033099
ORD	MIA	3.2938235294117647
ORD	DFW	2.7417554644808743
LAX	ATL	4.4048494208494208
ORD	EWR	2.2506115357887422
ORD	BOG	5.8300000000000000
BKK	HND	5.6592081031307551
IST	SSH	2.7084000000000000
DEL	FRA	9.1560248447204969
ALG	FRA	2.7500000000000000
ORD	SFO	4.8685402184707051
ORD	ZRH	8.6700000000000000
ATL	DEN	3.4860020449897751
FRA	MUC	0.92000000000000000000
LAX	LAS	1.2583942558746736
LAX	MUC	11.2190000000000000
LAX	LHR	10.5000000000000000
FRA	OSL	2.0800000000000000
MUC	CAI	3.7002222222222222
MUC	SFO	11.9607741935483871
ATL	LAX	5.1182983870967742
MUC	OSL	2.3300000000000000
BER	DXB	6.3300000000000000
MIA	EWR	3.1984642857142857
IST	PVG	10.3750000000000000
NCE	BER	2.0000000000000000
NLU	MIA	3.0800000000000000
AMS	VIE	1.8300000000000000
PAE	LAX	2.8243750000000000
ARN	MUC	2.2500000000000000
VIE	MUC	1.00120833333333333333
CDG	SFO	11.4200000000000000
VIE	LHR	2.4452506596306069
ZRH	LAX	12.3300000000000000
ZRH	LIS	2.9888297872340426
CLT	MCO	1.7809213863060017
MEX	ORD	4.2098876404494382
ATL	MCO	1.5330303030303030
DAL	ATL	2.0110103626943005
SEA	ATL	4.8062861491628615
DFW	ONT	3.3857714285714286
DFW	LAX	3.5078733031674208
SEA	ORD	4.4076332622601279
SEA	DAL	3.9535616438356164
SEA	ONT	2.6419420289855072
GRU	DFW	10.4819047619047619
GRU	MEX	9.3081818181818182
DFW	MIA	2.9019189189189189
DEN	LAS	2.1104979253112033
CAI	MUC	4.0800000000000000
CPT	FRA	11.9200000000000000
DFW	ORD	2.4338524590163934
ATL	GRU	9.4886746987951807
ATL	DAL	2.3135439560439560
BKK	PEK	4.5987155963302752
DEN	MUC	9.6608737864077670
DFW	JFK	3.5223887587822014
SSH	CAI	1.4484636871508380
MRU	FRA	12.0000000000000000
DEN	FRA	9.6206716417910448
\.


--
-- Name: Airport_id_seq; Type: SEQUENCE SET; Schema: flight_routes; Owner: dst_graph_designer
--

SELECT pg_catalog.setval('flight_routes."Airport_id_seq"', 61, true);


--
-- Name: ROUTE_id_seq; Type: SEQUENCE SET; Schema: flight_routes; Owner: dst_graph_designer
--

SELECT pg_catalog.setval('flight_routes."ROUTE_id_seq"', 603, true);


--
-- Name: _ag_label_edge_id_seq; Type: SEQUENCE SET; Schema: flight_routes; Owner: dst_graph_designer
--

SELECT pg_catalog.setval('flight_routes._ag_label_edge_id_seq', 1, false);


--
-- Name: _ag_label_vertex_id_seq; Type: SEQUENCE SET; Schema: flight_routes; Owner: dst_graph_designer
--

SELECT pg_catalog.setval('flight_routes._ag_label_vertex_id_seq', 1, false);


--
-- Name: _label_id_seq; Type: SEQUENCE SET; Schema: flight_routes; Owner: dst_graph_designer
--

SELECT pg_catalog.setval('flight_routes._label_id_seq', 4, true);


--
-- Name: _ag_label_edge _ag_label_edge_pkey; Type: CONSTRAINT; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER TABLE ONLY flight_routes._ag_label_edge
    ADD CONSTRAINT _ag_label_edge_pkey PRIMARY KEY (id);


--
-- Name: _ag_label_vertex _ag_label_vertex_pkey; Type: CONSTRAINT; Schema: flight_routes; Owner: dst_graph_designer
--

ALTER TABLE ONLY flight_routes._ag_label_vertex
    ADD CONSTRAINT _ag_label_vertex_pkey PRIMARY KEY (id);


--
-- Name: scheduled_routes scheduled_routes_pkey; Type: CONSTRAINT; Schema: l3; Owner: dst_graph_designer
--

ALTER TABLE ONLY l3.scheduled_routes
    ADD CONSTRAINT scheduled_routes_pkey PRIMARY KEY (departure_airport_code, arrival_airport_code);


--
-- Name: scheduled_routes scheduled_routes_pkey; Type: CONSTRAINT; Schema: public; Owner: dst_graph_designer
--

ALTER TABLE ONLY public.scheduled_routes
    ADD CONSTRAINT scheduled_routes_pkey PRIMARY KEY (departure_airport_code, arrival_airport_code);


--
-- Name: scheduled_routes trigger_autoload_scheduled_routes; Type: TRIGGER; Schema: public; Owner: dst_graph_designer
--

CREATE TRIGGER trigger_autoload_scheduled_routes AFTER INSERT OR UPDATE ON public.scheduled_routes FOR EACH ROW EXECUTE FUNCTION flight_routes.autoload_scheduled_routes();


--
-- PostgreSQL database dump complete
--

