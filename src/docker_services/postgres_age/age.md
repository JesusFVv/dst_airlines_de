# Apache AGE: Graphe Database for PostgreSQL

[Quickstart guide to AGE](https://age.apache.org/getstarted/quickstart/).

## Installation with Docker: PostgresSQL with AGE extension

```bash
# Get the image
docker pull apache/age
# Run the PostgreSQL + AGE container
docker run -d \
--name age  \
-p 5455:5432 \
-e POSTGRES_USER=postgresUser \
-e POSTGRES_PASSWORD=postgresPW \
-e POSTGRES_DB=postgresDB \
--network dst_network \
--restart unless-stopped \
apache/age
# Enter the container
docker exec -it age psql -d postgresDB -U postgresUser
```
### Connection settings

In order to allowing the automatic dump of table l3.schedules_routes from `dst_airlines_db`, we need to allow all the connections and trust them for the incoming IP of the docker gateway.

So, we need to modify the `pg_hba.conf` file:
- Delete last line: `host all all all scram-sha-256`
- Add the line: `host all all 172.0.0.0/8 trust`


## Quickstart

For every connection of AGE load the extension.
```sql
CREATE EXTENSION age;
LOAD 'age';
SET search_path = ag_catalog, "$user", public;
```

```sql
-- Create a new graph. Function create_graph is located in the ag_catalog namespace
SELECT create_graph('graph_name');
-- Create a single vertex
SELECT * 
FROM cypher('graph_name', $$
    CREATE (n)
$$) as (v agtype);
-- Create single vertex with label
SELECT * 
FROM cypher('graph_name', $$
    CREATE (:label)
$$) as (v agtype);
-- Query the graph
SELECT * 
FROM cypher('graph_name', $$
    MATCH (v)
    RETURN v
$$) as (v agtype);
-- Create an edge between two nodes
SELECT * 
FROM cypher('graph_name', $$
    MATCH (a:label), (b:label)
    WHERE a.property = 'Node A' AND b.property = 'Node B'
    CREATE (a)-[e:RELTYPE]->(b)
    RETURN e
$$) as (e agtype);
-- Create an edge with properties
SELECT * 
FROM cypher('graph_name', $$
    MATCH (a:label), (b:label)
    WHERE a.property = 'Node A' AND b.property = 'Node B'
    CREATE (a)-[e:RELTYPE {property:a.property + '<->' + b.property}]->(b)
    RETURN e
$$) as (e agtype);

SELECT * 
FROM cypher('graph_name', $$
    MATCH (a:Person), (b:Person)
    WHERE a.name = 'Node A' AND b.name = 'Node B'
    CREATE (a)-[e:RELTYPE {name:a.name + '<->' + b.name}]->(b)
    RETURN e
$$) as (e agtype);
```

Example with airports.
```sql
-- Create a new graph to store routes
SELECT create_graph('graph_flight_routes');
-- Create three nodes (airports): FRA, CDG, LOZ
SELECT *
FROM cypher('graph_flight_routes', $$
    CREATE (:Airport {code: 'FRA'})
$$) as (v agtype);
SELECT *
FROM cypher('graph_flight_routes', $$
    CREATE (:Airport {code: 'CDG'})
$$) as (v agtype);
SELECT *
FROM cypher('graph_flight_routes', $$
    CREATE (:Airport {code: 'LOZ'})
$$) as (v agtype);
-- Create routes from FRA to CDG, CDG to LOZ, FRA to LOZ and LOZ to CDG
SELECT * 
FROM cypher('graph_flight_routes', $$
    MATCH (a:Airport), (b:Airport)
    WHERE a.code = 'FRA' AND b.code = 'CDG'
    CREATE (a)-[e:RELTYPE {route:a.code + '<->' + b.code}]->(b)
    RETURN e
$$) as (e agtype);
SELECT * 
FROM cypher('graph_flight_routes', $$
    MATCH (a:Airport), (b:Airport)
    WHERE a.code = 'CDG' AND b.code = 'LOZ'
    CREATE (a)-[e:RELTYPE {route:a.code + '<->' + b.code}]->(b)
    RETURN e
$$) as (e agtype);
SELECT * 
FROM cypher('graph_flight_routes', $$
    MATCH (a:Airport), (b:Airport)
    WHERE a.code = 'FRA' AND b.code = 'LOZ'
    CREATE (a)-[e:RELTYPE {route:a.code + '<->' + b.code}]->(b)
    RETURN e
$$) as (e agtype);
SELECT * 
FROM cypher('graph_flight_routes', $$
    MATCH (a:Airport), (b:Airport)
    WHERE a.code = 'LOZ' AND b.code = 'CDG'
    CREATE (a)-[e:RELTYPE {route:a.code + '<->' + b.code}]->(b)
    RETURN e
$$) as (e agtype);
-- Query the available routes from FRA to LOZ (there is 2)
SELECT *
FROM cypher('graph_flight_routes', $$
    MATCH p = (:Airport {code: 'FRA'})-[*]->(:Airport {code: 'LOZ'})
    RETURN relationships(p)
$$) as (routes agtype);
-- Query the available routes from LOZ to FRA (there is 0)
SELECT *
FROM cypher('graph_flight_routes', $$
    MATCH p = (:Airport {code: 'LOZ'})-[*]->(:Airport {code: 'FRA'})
    RETURN relationships(p)
$$) as (routes agtype);
-- Query the available routes from FRA to CDG (there is 3, the third dont make sens
SELECT *
FROM cypher('graph_flight_routes', $$
    MATCH p = (:Airport {code: 'FRA'})-[*]->(:Airport {code: 'CDG'})
    RETURN relationships(p)
$$) as (routes agtype);
-- Query the available routes from CDG to LOZ (there is 1)
SELECT *
FROM cypher('graph_flight_routes', $$
    MATCH p = (:Airport {code: 'CDG'})-[*]->(:Airport {code: 'LOZ'})
    RETURN relationships(p)
$$) as (routes agtype);
-- Query the available routes from LOZ to CDG (there is 1)
SELECT *
FROM cypher('graph_flight_routes', $$
    MATCH p = (:Airport {code: 'LOZ'})-[:RELTYPE*]->(:Airport {code: 'CDG'})
    RETURN relationships(p)
$$) as (routes agtype);

SELECT *
FROM cypher('graph_flight_routes', $$
    MATCH p = (:Airport {code: 'FRA'})-[:RELTYPE*]->(:Airport {code: 'LOZ'})
    WHERE NOT ((:Airport {code: 'LOZ'})-[:RELTYPE]->(:Airport))
    RETURN nodes(p)
$$) as (routes agtype);


SELECT *
FROM cypher('graph_flight_routes', $$
    MATCH p = ((:Airport {code: 'FRA'})-[r:RELTYPE*]->(:Airport {code: 'LOZ'}))
    UNWIND nodes(p) AS n
    RETURN n.code
$$) as (routes agtype);



SELECT *
FROM cypher('graph_flight_routes', $$
    CREATE (:Airport {code: 'FRA'})-[:FROM_TO {route: 'FRA->CDG'}]->(:Airport {code: 'CDG'})
$$) as (a agtype)


```



