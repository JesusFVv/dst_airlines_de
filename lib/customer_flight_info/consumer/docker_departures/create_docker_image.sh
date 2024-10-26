#!/usr/bin/env bash
# Execute the script with command:
#   bash lib/customer_flight_info/consumer/docker_departures/create_docker_image.sh
set -a
source .env
set +a
pushd ${CUSTOMER_FLIGHT_INFO_CONSUMER_DOCKER_PATH}/docker_departures
docker build -t dst_customer_flight_information_departures_consumer -f Dockerfile ../../../
popd