#!/usr/bin/env bash
# Dump the complete data base in a SQL file
# Launch the script with command:
# bash lib/db_dump/restore_db_dump.sh
set -a
source .env
set +a
FILE_NAME=$1

docker exec $POSTGRES_CONTAINER_NAME sh -c "gunzip -c /var/backups/${FILE_NAME} | psql --set ON_ERROR_STOP=0 $POSTGRES_DB -U dst_designer"

# Extract the SQL file from the GZIP
# FILE_NAME=20241026_213116_dst_airlines_db_dump.sql.gz
# gunzip -c var/db_dumps/${FILE_NAME} > var/db_dumps/${FILE_NAME%.gz}