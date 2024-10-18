#!/usr/bin/env bash
set -a
source .env
set +a
CONTAINER_NAME=flight_schedules_consumer2
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
pushd lib/flights_scheduled/extraction
docker container run -d --name $CONTAINER_NAME \
    -e RABBITMQ_HOST=$RABBITMQ_HOST \
    -e RABBITMQ_PORT=$RABBITMQ_PORT \
    -e FLIGHT_SCHEDULES_CHANNEL=$FLIGHT_SCHEDULES_CHANNEL \
    --network dst_network \
    --restart always \
    dst_flight_schedules_consumer
popd