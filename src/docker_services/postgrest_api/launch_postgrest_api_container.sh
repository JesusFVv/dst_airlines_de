#!/usr/bin/env bash
# execute it with command: bash src/docker/nginx/launch_postgrest_api_container.sh

# Load environmental variables for PostgRest server: with READ-ONLY permissions
PGRST_DB_URI="postgres://postgrest_authenticator:pass_api@postgres_dst:5432/dst_airlines_db"
PGRST_DB_SCHEMA="public"
PGRST_DB_ANON_ROLE="web_anonimous"
PGRST_DB_AGGREGATES_ENABLED="true"
# Run the server
CONTAINER_NAME=postgrest_api
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
docker run --name ${CONTAINER_NAME} \
  -e PGRST_DB_URI=${PGRST_DB_URI} \
  -e PGRST_DB_SCHEMAS=${PGRST_DB_SCHEMA} \
  -e PGRST_DB_ANON_ROLE=${PGRST_DB_ANON_ROLE} \
  -e PGRST_DB_AGGREGATES_ENABLED=${PGRST_DB_AGGREGATES_ENABLED} \
  --network dst_network \
  --restart unless-stopped \
  -d postgrest/postgrest:v12.2.3

# -p 3000:3000 \  # Not needed to expose port because we access it via Nginx
