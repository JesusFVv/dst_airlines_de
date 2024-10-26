#!/usr/bin/env bash

# Launch a test DB
docker container run --rm -d --name db_test \
    -e POSTGRES_DB=dst_airlines_db \
    -e POSTGRES_USER=dst_designer \
    -e POSTGRES_PASSWORD=toto \
    -p 5434:5432 \
    -v /home/ubuntu-user1/prj/dst_airlines_project/dst_airlines_de/var/db_dumps:/var/backups:ro \
    postgres:16.3-bullseye

# Restore the dump

FILE_NAME=20241026_133835_dst_airlines_db_dump.sql.gz
docker exec db_test sh -c "gunzip -c /var/backups/${FILE_NAME} | psql dst_airlines_db -U dst_designer"