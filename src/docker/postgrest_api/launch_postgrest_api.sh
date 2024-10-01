#!/usr/bin/env bash
# Load environmental variables for PostgRest server
PGRST_DB_URI="postgres://postgrest_authenticator:pass_api@172.19.0.9:5432/dst_airlines_db"
PGRST_DB_SCHEMAS="public"
PGRST_DB_ANON_ROLE="web_anonimous"
PGRST_DB_AGGREGATES_ENABLED="true"
# Run the server
docker run --rm --net=host \
  -e PGRST_DB_URI=PGRST_DB_URI \
  -e PGRST_DB_SCHEMAS=PGRST_DB_SCHEMAS \
  -e PGRST_DB_ANON_ROLE=PGRST_DB_ANON_ROLE \
  -e PGRST_DB_AGGREGATES_ENABLED=PGRST_DB_AGGREGATES_ENABLED \
  postgrest/postgrest
