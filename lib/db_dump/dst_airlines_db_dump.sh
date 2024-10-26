#!/usr/bin/env bash
# Dump the complete data base in a SQL file
# Launch the script with command:
# bash lib/db_dump/dst_airlines_db_dump.sh
set -a
source .env
set +a

docker exec $POSTGRES_CONTAINER_NAME pg_dump $POSTGRES_DB -U dst_designer > var/db_dumps/$(date +%Y%m%d_%H%M%S_)dst_airlines_db_dump.sql

