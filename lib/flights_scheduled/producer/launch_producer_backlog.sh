#!/usr/bin/env bash
set -a
source .env
set +a
CONTAINER_NAME=flight_schedules_producer_backlog
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
pushd lib/flights_scheduled/producer
docker container run -d --name $CONTAINER_NAME \
    -e AIRPORTS_FILE_PATH=/usr/src/app/data/airports.csv \
    -e RABBITMQ_HOST=$RABBITMQ_HOST \
    -e RABBITMQ_PORT=$RABBITMQ_PORT \
    -e FLIGHT_SCHEDULES_CHANNEL=$FLIGHT_SCHEDULES_CHANNEL \
    -v ${PROJECT_ABSOLUT_PATH}/data/airports/airports.csv:/usr/src/app/data/airports.csv:ro \
    --network dst_network \
    --restart no \
    dst_flight_schedules_producer_backlog
popd