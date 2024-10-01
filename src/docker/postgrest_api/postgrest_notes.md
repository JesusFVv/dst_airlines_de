# PostgRest API

[PostgRest API](https://docs.postgrest.org/en/v12/index.html), is a webserber that turns the PostgreSQL db in a RESTful API. The structure and permissions in the DB are the API endpoints.

## Installation

### With the Binary

```bash
# download from https://github.com/PostgREST/postgrest/releases/latest
POSTGREST_BINARY_PATH=src/docker/postgrest_api/postgrest-v12.2.3-linux-static-x64.tar.xz
pushd src/docker/postgrest_api
tar xJf postgrest-v12.2.3-linux-static-x64.tar.xz
./postgrest -h
```

### With Docker


## PostgreSQL configuration

Create anonimous role to grant read acces to the specified schema and tables of the DB, for the web requests.

```sql
create role web_anonimous nologin;
grant usage on schema public to web_anonimous;
grant select on all tables in schema public to web_anonimous;
```

Create an user in order to the RESTAPI, to be able to log in
```sql
create role postgrest_authenticator noinherit login password 'pass_api';
grant web_anonimous to postgrest_authenticator;
```

## Create postgRest file configuration

```conf
db-uri = "postgres://postgrest_authenticator:pass_api@172.19.0.9:5432/dst_airlines_db"
db-schemas = "public"
db-anon-role = "web_anonimous"
db-aggregates-enabled = "true"  # to enable aggregations
```

## Launch PostgRest server

```bash
./postgrest postgrest.conf
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
# 
```


## Restart conf

```bash
killall -SIGUSR1 postgrest
# or in docker
docker kill -s SIGUSR1 <container>
# or in docker-compose
docker-compose kill -s SIGUSR1 <service>
```