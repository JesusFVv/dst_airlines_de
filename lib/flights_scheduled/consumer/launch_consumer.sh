#!/usr/bin/env bash
# RABBITMQ_HOST = 
#   - $RABBITMQ_HOST (IP of the rabbitmq container) if launch in other than the project network
#   - $RABBITMQ_CONTAINER_NAME if launch in project network
# Execute script with command:
#   bash lib/flights_scheduled/consumer/launch_consumer.sh
set -a
source .env
set +a
CONTAINER_NAME=flight_schedules_consumer
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
pushd lib/flights_scheduled/consumer
docker container run -d --name $CONTAINER_NAME \
    -e RABBITMQ_HOST=$RABBITMQ_CONTAINER_NAME \
    -e RABBITMQ_PORT=$RABBITMQ_PORT \
    -e FLIGHT_SCHEDULES_CHANNEL=$FLIGHT_SCHEDULES_CHANNEL \
    -e LOG_FILE_PATH=/usr/src/app/log \
    -v ${FLIGHT_SCHEDULES_CONSUMER_DOCKER_PATH}/.dlt/secrets.toml:/usr/src/app/.dlt/secrets.toml:ro \
    -v ${FLIGHT_SCHEDULES_CONSUMER_LOG_PATH}:/usr/src/app/log:rw \
    --network $PROJECT_NETWORK_1 \
    --restart always \
    dst_flight_schedules_consumer
popd