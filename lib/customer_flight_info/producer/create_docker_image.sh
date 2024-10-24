#!/usr/bin/env bash
# Create an image to fill the queue with flight routes by a given date in the future
# Execute the script with command:
#   bash lib/customer_flight_info/producer/create_docker_image.sh
set -a
source .env
set +a
pushd ${PROJECT_ABSOLUT_PATH}/lib/customer_flight_info/producer
docker build -t dst_customer_flight_info_producer .
popd
