#!/bin/bash
# Command to execute this script:
#   bash bin/reference_data/full_ingest/launch_docker_container.sh

# Load environment variables
set -a
source .env
set +a

# Run Docker
docker run --rm \
  -e POSTGRES_HOST=$POSTGRES_HOST \
  -e POSTGRES_DB=$POSTGRES_DB \
  -e POSTGRES_DB_PORT=$POSTGRES_DB_PORT \
  -v ${PROJECT_ABSOLUT_PATH}/data/referenceData:/usr/src/app/data/referenceData \
  -v ${PROJECT_ABSOLUT_PATH}/etc/postgres:/usr/src/app/etc:ro \
  --network $PROJECT_NETWORK_1 \
  --name $REFERENCE_DATA_CONTAINER_NAME \
  $REFERENCE_DATA_IMAGE_NAME


# D - INGEST RAW
# python3 ./ingestRefData_02_ingestReferenceDataRaw.py

# # E - INGEST COOKED
# python3 ./common/runSqlScript.py ./ingestRefData_03_referenceDataCooked.sql