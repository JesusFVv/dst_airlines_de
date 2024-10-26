#!/usr/bin/env bash
# Dump the complete data base in a SQL file
# Launch the script with command:
# bash lib/db_dump/dst_airlines_db_dump.sh
set -a
source .env
set +a
FILE_NAME=$0

docker exec $POSTGRES_CONTAINER_NAME sh -c "gunzip -c /var/backups/${FILE_NAME} | psql $POSTGRES_DB -U dst_designer"
