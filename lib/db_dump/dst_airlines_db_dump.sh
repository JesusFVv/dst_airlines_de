#!/usr/bin/env bash
# Dump the complete data base in a SQL file
# Launch the script with command:
# bash lib/db_dump/dst_airlines_db_dump.sh
set -a
source .env
set +a

FILE_NAME=$(date +%Y%m%d_%H%M%S_)dst_airlines_db_dump.sql.gz

docker exec $POSTGRES_CONTAINER_NAME sh -c "pg_dump $POSTGRES_DB -U dst_designer | gzip > /var/backups/$FILE_NAME"

# Extract the SQL file from the GZIP
# FILE_NAME=20241026_213116_dst_airlines_db_dump.sql.gz
# gunzip -c var/db_dumps/${FILE_NAME} > var/db_dumps/${FILE_NAME%.gz}
