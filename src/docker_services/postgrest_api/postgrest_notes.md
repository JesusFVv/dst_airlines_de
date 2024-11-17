# PostgRest API

[PostgRest API](https://docs.postgrest.org/en/v12/index.html), is a webserber that turns the PostgreSQL db in a RESTful API. The structure and permissions in the DB are the API endpoints.

## Configuration

### PostgreSQL DB

Two step process to follow good practices:
- First, create a new role with specific permissions (read only in this example).
- Second, create a new user to be able to login and grant the previous role.

Create anonimous role to grant read acces to the specified schema and tables of the DB, for the web requests.

```sql
create role web_anonimous nologin;
grant usage on schema l2 to web_anonimous;
grant select on all tables in schema l2 to web_anonimous;
grant usage on schema l3 to web_anonimous;
grant select on all tables in schema l3 to web_anonimous;
```

Create an user in order to login to the RESTAPI
```sql
create role postgrest_authenticator noinherit login password 'pass_api';
grant web_anonimous to postgrest_authenticator;
```

### PostgRest API

If we use the binary, we need to create a config file (ex. `postgrest.conf`), with following content. This will allow us to connect as `postgrest_authenticator` with read-only permissions on all the tables in the `public` schema.

```conf
db-uri = "postgres://postgrest_authenticator:pass_api@postgres_dst:5432/dst_airlines_db"
db-schemas = "public"
db-anon-role = "web_anonimous"
db-aggregates-enabled = "true"  # to enable aggregations
```

## Launch the PostgRest API server

### With the Binary

```bash
# download from https://github.com/PostgREST/postgrest/releases/latest
POSTGREST_BINARY_PATH=src/docker/postgrest_api/postgrest-v12.2.3-linux-static-x64.tar.xz
pushd src/docker/postgrest_api
tar xJf postgrest-v12.2.3-linux-static-x64.tar.xz
./postgrest -h
# Launch the server with the config file defined in previous section
./postgrest postgrest.conf
```

### With Docker

Launch the following script, to start a container with the PostgRest API v12.2.3, and a Read-Only role created in the next section.

```bash
#!/usr/bin/env bash
# execute it with command: bash src/docker/nginx/launch_postgrest_api_container.sh

# Load environmental variables for PostgRest server: with READ-ONLY permissions
PGRST_DB_URI="postgres://postgrest_authenticator:pass_api@postgres_dst:5432/dst_airlines_db"
PGRST_DB_SCHEMAS="public"
PGRST_DB_ANON_ROLE="web_anonimous"
PGRST_DB_AGGREGATES_ENABLED="true"
# Run the server
CONTAINER_NAME=postgrest_api
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
docker run --name ${CONTAINER_NAME} \
  -e PGRST_DB_URI=${PGRST_DB_URI} \
  -e PGRST_DB_SCHEMAS=${PGRST_DB_SCHEMAS} \
  -e PGRST_DB_ANON_ROLE=${PGRST_DB_ANON_ROLE} \
  -e PGRST_DB_AGGREGATES_ENABLED=${PGRST_DB_AGGREGATES_ENABLED} \
  --network dst_network \
  -p 3000:3000 \ 
  --restart unless-stopped \
  -d postgrest/postgrest:v12.2.3
```

### Restart Server

If you need to update the configuration file, you can restart the server with:

```bash
# If binary
killall -SIGUSR1 postgrest
# or in docker
docker kill -s SIGUSR1 <container>
# or in docker-compose
docker-compose kill -s SIGUSR1 <service>
```

## TODO

- Apply authentication [tutorial](https://docs.postgrest.org/en/v12/tutorials/tut1.html)
- Do other type of queries: POST, PACH, DELETE (DML)
- Implement a Swagger UI


## Apply multiple schemas

In the config file we can declare a list of schemas as:
```log
db-schemas = "tenant1, tenant2"
```

In order to query in different schemas we need to use the headers "Accept-Profile" for GET/HEAD and "Content-Profile" for POST, PUT, DELETE.

```bash
curl "http://localhost:3000/items" \
  -H "Accept-Profile: tenant2"
```


## Start querying the DB

```bash
# List all the cities & countries in the DB
curl "http://localhost:3000/refdata_cities_coo"
# List the cities for the country France (country=FR)
curl "http://localhost:3000/refdata_cities_coo?country=eq.FR"
# Count the number of cities for the country France
curl "http://localhost:3000/refdata_cities_coo?country=eq.FR&select=count()"
# Count the number of cities by country in the DB
curl "http://localhost:3000/refdata_cities_coo?select=count(),country"
```

## Nginx reverse proxy

```conf
server {
  ...
  location /postgrest_api/ {
            default_type  application/json;
            proxy_hide_header Content-Location;
            add_header Content-Location  /api/$upstream_http_content_location;
            proxy_set_header  Connection "";
            proxy_http_version 1.1;
            proxy_pass http://postgrest_api:3000/;
    }
  ...
}
```