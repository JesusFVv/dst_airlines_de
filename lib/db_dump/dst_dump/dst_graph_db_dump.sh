#!/usr/bin/env bash
# Dump the complete data base in a SQL file
# Launch the script with command:
# bash lib/db_dump/dst_dump/dst_graph_db_dump.sh
set -a
source .env
set +a

FILE_NAME=$(date +%Y%m%d_%H%M%S_)dst_graph_db_dump.sql.gz

docker exec $POSTGRES_AGE_CONTAINER_NAME sh -c "pg_dump $POSTGRES_AGE_DB -U $POSTGRES_AGE_USER | gzip > /var/backups/$FILE_NAME"

# Extract the SQL file from the GZIP
# FILE_NAME=20241031_164706_dst_airlines_db_dump.sql.gz
# gunzip -c var/db_dumps/${FILE_NAME} > var/db_dumps/${FILE_NAME%.gz}
