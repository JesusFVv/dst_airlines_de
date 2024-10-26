#!/usr/bin/env bash
# Execute the script with command:
#   bash lib/flights_scheduled/consumer/create_docker_image.sh
set -a
source .env
set +a
pushd ${PROJECT_ABSOLUT_PATH}/lib/flights_scheduled/consumer
docker build -t dst_flight_schedules_consumer .
popd