#!/usr/bin/env bash
# Execute script with command:
#   bash src/docker_services/jupyterhub/launch_jupyterhub_container.sh
set -a
source .env
set +a
CONTAINER_NAME=$JUPYTERHUB_CONTAINER_NAME
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
docker container run -d --name $CONTAINER_NAME \
    -v ${JUPYTERHUB_CONFIG_FILE}:/etc/jupyterhub/jupyterhub_config.py:ro \
    -v ${JUPYTERHUB_HOME}:/home:rw \
    -v ${JUPYTERHUB_DB}:/srv/jupyterhub:rw \
    --network $PROJECT_NETWORK_1 \
    --restart always \
    jupyterhub
