#!/usr/bin/env bash
# execute it with command:
# bash src/docker_services/postgres_age/launch_postgres_age_container.sh
set -a
source .env
set +a

CONTAINER_NAME=$POSTGRES_AGE_CONTAINER_NAME
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
docker run --name $CONTAINER_NAME \
-e POSTGRES_USER=$POSTGRES_AGE_USER \
-e POSTGRES_PASSWORD=$POSTGRES_AGE_USER_PASS \
-e POSTGRES_DB=$POSTGRES_AGE_DB \
-v graph_db-data:/var/lib/postgresql/data \
-v ${POSTGRES_AGE_INIT_FILES_PATH}/1_config_acces.sh:/docker-entrypoint-initdb.d/1_config_acces.sh:ro \
-v ${POSTGRES_AGE_DUMP_DIR}:/var/backups:rw \
--network $PROJECT_NETWORK_1 \
--restart unless-stopped \
-d apache/age
