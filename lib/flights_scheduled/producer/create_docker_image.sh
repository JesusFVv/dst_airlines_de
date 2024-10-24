#!/usr/bin/env bash
# Execute the script with command:
#   bash lib/flights_scheduled/producer/create_docker_image.sh
set -a
source .env
set +a
pushd ${PROJECT_ABSOLUT_PATH}/lib/flights_scheduled/producer
docker build -t dst_flight_schedules_producer .
popd
