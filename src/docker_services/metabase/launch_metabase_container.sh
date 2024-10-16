#!/usr/bin/env bash
# execute it with command: bash src/docker/nginx/launch_nginx_container.sh

set -a
source .env
set +a

CONTAINER_NAME=metabase
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
docker run --name ${CONTAINER_NAME} \
-v ${PROJECT_ABSOLUT_PATH}/var/metabase/data:/metabase-data \
-e MB_DB_FILE=/metabase-data/metabase.db -e MUID=$SERVICES_UID -e MGID=$SERVICES_GID \
-e "JAVA_TIMEZONE=Europe/Paris" -e "JAVA_OPTS=-Xmx3g" \
-e MB_JETTY_HOST=0.0.0.0 -e MB_JETTY_PORT=3000 \
--network dst_network \
--restart unless-stopped \
-d metabase/metabase

# -p 3000:3000

