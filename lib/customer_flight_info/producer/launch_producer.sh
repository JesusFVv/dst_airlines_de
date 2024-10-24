#!/usr/bin/env bash
# Launch script wit command: bash lib/customer_flight_info/producer/launch_producer.sh
set -a
source .env
set +a
CONTAINER_NAME=customer_flight_info_producer
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
pushd lib/customer_flight_info/producer
docker container run -d --name $CONTAINER_NAME \
    -e AIRPORTS_FILE_PATH=/usr/src/app/data/airports.csv \
    -e RABBITMQ_HOST=$RABBITMQ_HOST \
    -e RABBITMQ_PORT=$RABBITMQ_PORT \
    -e CUSTOMERS_FLIGHT_INFO_ARRIVALS_CHANNEL=$CUSTOMERS_FLIGHT_INFO_ARRIVALS_CHANNEL \
    -e CUSTOMERS_FLIGHT_INFO_DEPARTURES_CHANNEL=$CUSTOMERS_FLIGHT_INFO_DEPARTURES_CHANNEL \
    -e LOG_FILE_PATH=/usr/src/app/log \
    -v ${AIRPORTS_FILE_DIR}:/usr/src/app/data:ro \
    -v ${CUSTOMER_FLIGHT_INFO_PRODUCER_LOG_PATH}:/usr/src/app/log:rw \
    --network dst_network \
    --restart no \
    dst_customer_flight_info_producer
popd
