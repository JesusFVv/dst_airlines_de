#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Run Docker
docker run \
  -e POSTGRES_HOST=${POSTGRES_HOST} \
  -e POSTGRES_DB=${POSTGRES_DB} \
  -e POSTGRES_DB_PORT=${POSTGRES_DB_PORT} \
  -v ${PROJECT_ABSOLUT_PATH}/data/customerFlightInfo:/usr/src/app/data/customerFlightInfo \  # This volume stores data
  -v ${PROJECT_ABSOLUT_PATH}/etc/postgres:/usr/src/app/etc:ro \  # This volume stores files for database connection
  --network $PROJECT_NETWORK_1 \
  --name ${CUSTOMER_FLIGHT_INFO_L1_LOADING_CONTAINER_NAME} \
  ${CUSTOMER_FLIGHT_INFO_L1_LOADING_IMAGE_NAME}
