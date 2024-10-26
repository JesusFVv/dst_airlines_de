#!/usr/bin/env bash
# Execute the script with command:
#   bash lib/customer_flight_info/consumer/docker_arrivals/create_docker_image.sh
set -a
source .env
set +a
pushd ${CUSTOMER_FLIGHT_INFO_CONSUMER_DOCKER_PATH}/docker_arrivals
docker build -t dst_customer_flight_information_arrivals_consumer -f Dockerfile ../../../
popd