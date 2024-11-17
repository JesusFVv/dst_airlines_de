#!/usr/bin/env bash
# Build the custom images for this project

# Customer Flight Information
## Producer
bash lib/customer_flight_info/producer/create_docker_image.sh
## Consumer
bash lib/customer_flight_info/consumer/docker_arrivals/create_docker_image.sh
bash lib/customer_flight_info/consumer/docker_departures/create_docker_image.sh
## Incremental Loading l1 to l2
bash lib/customer_flight_info/l2_loading_incremental/create_docker_image.sh

# Flight Schedules
## Producer
bash lib/flights_scheduled/producer/create_docker_image.sh
## Consumer
bash lib/flights_scheduled/consumer/create_docker_image.sh

# JupyterHub
bash src/docker_services/jupyterhub/create_docker_image.sh
