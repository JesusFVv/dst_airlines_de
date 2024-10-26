#!/usr/bin/env bash
# RABBITMQ_HOST = 
#   - $RABBITMQ_HOST (IP of the rabbitmq container) if launch in other than the project network
#   - $RABBITMQ_CONTAINER_NAME if launch in project network
# Execute script with command:
#   bash lib/customer_flight_info/consumer/docker_departures/launch_consumer.sh
set -a
source .env
set +a
CONTAINER_NAME=customer_flight_information_departures_consumer
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
docker container run -d --name $CONTAINER_NAME \
    -e RABBITMQ_HOST=$RABBITMQ_CONTAINER_NAME \
    -e RABBITMQ_PORT=$RABBITMQ_PORT \
    -e POSTGRES_HOST=$POSTGRES_HOST \
    -e POSTGRES_DB=$POSTGRES_DB \
    -e POSTGRES_DB_PORT=$POSTGRES_DB_PORT \
    -e CUSTOMERS_FLIGHT_INFO_DEPARTURES_CHANNEL=$CUSTOMERS_FLIGHT_INFO_DEPARTURES_CHANNEL \
    -e CUSTOMER_FLIGHT_INFO_TABLE_NAME=$CUSTOMER_FLIGHT_INFO_TABLE_NAME \
    -e LOG_FILE_PATH=/usr/src/app/log \
    -e AIRPORTS_FILE_PATH=/usr/src/app/data/airports.csv \
    -v ${CUSTOMER_FLIGHT_INFO_CONSUMER_LOG_PATH}:/usr/src/app/log:rw \
    -v ${FLIGHT_SCHEDULES_CONSUMER_DOCKER_PATH}/.dlt/secrets.toml:/usr/src/app/secrets.toml:ro \
    -v ${PROJECT_ABSOLUT_PATH}/etc/postgres:/usr/src/app/etc:ro \
    -v ${AIRPORTS_FILE_DIR}:/usr/src/app/data:ro \
    --network $PROJECT_NETWORK_1 \
    --restart always \
    dst_customer_flight_information_departures_consumer

