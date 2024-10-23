#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Run Docker
docker run \
  -v ${PROJECT_ABSOLUT_PATH}/data/customerFlightInfo:/usr/src/app/data/customerFlightInfo \  # This volume stores data
  --name ${CUSTOMER_FLIGHT_INFO_EXTRACT_CONTAINER_NAME} \
  ${CUSTOMER_FLIGHT_INFO_EXTRACT_IMAGE_NAME}
