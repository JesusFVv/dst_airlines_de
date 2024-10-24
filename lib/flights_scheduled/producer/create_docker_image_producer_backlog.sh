#!/usr/bin/env bash
# This image fills the queue with a backlog of routes and dates from a start date to and end date
# Execute the script with command:
#   bash lib/flights_scheduled/producer/create_docker_image_producer_backlog.sh
# IMPORTANT: Before creating the image, change in the script producer.py line 96 the funciton get_flight_date() by get_flight_dates_for_backlog()
set -a
source .env
set +a
pushd ${PROJECT_ABSOLUT_PATH}/lib/flights_scheduled/producer
docker build -t dst_flight_schedules_producer_backlog .
popd
