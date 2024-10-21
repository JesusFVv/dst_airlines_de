#!/bin/bash
# Command to execute this script:
#   bash bin/reference_data/full_ingest/run_docker.sh

# Load environment variables
set -a
source .env
set +a

# Run Docker
docker run \
  --volume ${PROJECT_ABSOLUT_PATH}/data/referenceData:/usr/src/app/data/referenceData \
  -e POSTGRES_DBUSER_FILE=$POSTGRES_DBUSER_FILE \
  -e POSTGRES_DBUSER_PASSWORD_FILE=$POSTGRES_DBUSER_PASSWORD_FILE \
  -e PGRST_HOST=$PGRST_HOST \
  -e POSTGRES_DB=$POSTGRES_DB \
  -e POSTGRES_DB_PORT=$POSTGRES_DB_PORT \
  --network $PROJECT_NETWORK_1 \
  --name $REFERENCE_DATA_CONTAINER_NAME \
  $REFERENCE_DATA_IMAGE_NAME
