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
  -v ${PROJECT_ABSOLUT_PATH}/etc/postgres:/usr/src/app/etc:ro \
  --network $PROJECT_NETWORK_1 \
  --name ${CUSTOMER_FLIGHT_INFO_L2_LOADING_CONTAINER_NAME} \
  ${CUSTOMER_FLIGHT_INFO_L2_LOADING_IMAGE_NAME}
