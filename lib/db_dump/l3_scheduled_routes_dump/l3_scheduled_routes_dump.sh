#!/usr/bin/env bash
# Dump from dst_airlines_db the table l3.scheduled_routes
# Export the table to the graph DB into the table public.scheduled_routes
# Launch the script with command:
# bash lib/db_dump/l3_scheduled_routes_dump/l3_scheduled_routes_dump.sh
set -a
source .env
set +a

docker exec $POSTGRES_CONTAINER_NAME sh -c "pg_dump -a -d $POSTGRES_DB -U $POSTGRES_DB_READER -t l3.scheduled_routes | psql -h $POSTGRES_AGE_CONTAINER_NAME -d $POSTGRES_AGE_DB -U $POSTGRES_AGE_USER"
docker exec $POSTGRES_AGE_CONTAINER_NAME sh -c "psql -v ON_ERROR_STOP=1 -d $POSTGRES_AGE_DB -U $POSTGRES_AGE_USER -c 'INSERT INTO public.scheduled_routes select * from l3.scheduled_routes on conflict (departure_airport_code, arrival_airport_code) do update set avg_flight_duration_hours = excluded.avg_flight_duration_hours;' -c 'DELETE FROM l3.scheduled_routes;'"
