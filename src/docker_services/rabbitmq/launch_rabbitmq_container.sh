#!/usr/bin/env bash
# Launches RabbitMQ container
# Port open in the container is 5672
# Volumen for the database in /var/lib/rabbitmq
# Default username / pass = guest / guest
# Launch script from project root with: bash src/docker_services/rabbitmq/launch_rabbitmq_container.sh

set -a
source .env
set +a

CONTAINER_NAME=rabbitmq
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
docker run -d --name $CONTAINER_NAME \
    -v ${PROJECT_ABSOLUT_PATH}/var/rabbitmq/data:/var/lib/rabbitmq \
    --network dst_network \
    --hostname my-rabbit \
    --restart unless-stopped \
    rabbitmq:3