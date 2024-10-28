#!/usr/bin/env bash
# Execute script with command:
#   bash lib/customer_flight_info/l2_loading_incremental/launch_docker_container.sh
set -a
source .env
set +a
CONTAINER_NAME=customer_flight_information_l2_incremental_loading
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
docker container run --rm -d --name $CONTAINER_NAME \
    -e POSTGRES_HOST=$POSTGRES_HOST \
    -e POSTGRES_DB=$POSTGRES_DB \
    -e POSTGRES_DB_PORT=$POSTGRES_DB_PORT \
    -e CUSTOMER_FLIGHT_INFO_L2_TABLE_NAME=$CUSTOMER_FLIGHT_INFO_L2_TABLE_NAME \
    -e CUSTOMER_FLIGHT_INFO_STAGGING_TABLE_NAME=$CUSTOMER_FLIGHT_INFO_STAGGING_TABLE_NAME \
    -e REFDATA_AIRPORTS_L2_TABLE_NAME=$REFDATA_AIRPORTS_L2_TABLE_NAME \
    -v ${CUSTOMER_FLIGHT_INFO_L2_INCREMENTAL_LOADING_LOG_PATH}:/usr/src/app/log:rw \
    -v ${PROJECT_ABSOLUT_PATH}/etc/postgres:/usr/src/app/etc:ro \
    --network $PROJECT_NETWORK_1 \
    --restart no \
    dst_customer_flight_information_l2_incremental_loading

