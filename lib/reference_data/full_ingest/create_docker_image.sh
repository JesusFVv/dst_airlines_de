#!/bin/bash
# Command to execute this script, from project root:
# bash lib/reference_data/full_ingest/create_docker_image.sh

# Load environment variables
set -a
source .env
set +a

# Set some variables
readonly tmp_build_context=${REFERENCE_DATA_DOCKER_INGESTION_PATH}/tmp_build_context

# Create a temporary folder that will serve as a build context for Docker
if [ -d ${tmp_build_context} ]; then
  rm -rf ${tmp_build_context}
fi
mkdir ${tmp_build_context}
cp ${REFERENCE_DATA_DOCKER_INGESTION_PATH}/{Dockerfile,requirements.txt} ${tmp_build_context} &>/dev/null
cp -r ${PROJECT_ABSOLUT_PATH}/lib/common/ ${tmp_build_context}
mv ${tmp_build_context}/common/.dockerignore ${tmp_build_context}
mkdir ${tmp_build_context}/reference_data
cp ${REFERENCE_DATA_INGESTION_PATH}/*.sh ${tmp_build_context}/reference_data
cp ${REFERENCE_DATA_INGESTION_PATH}/*.py ${tmp_build_context}/reference_data
cp ${REFERENCE_DATA_INGESTION_PATH}/*.sql ${tmp_build_context}/reference_data

# Remove container - it might be there from a previous run
docker container inspect $REFERENCE_DATA_CONTAINER_NAME &>/dev/null && docker container rm $REFERENCE_DATA_CONTAINER_NAME
# Remove images - they might be there from a previous build
docker image inspect $REFERENCE_DATA_IMAGE_NAME &>/dev/null && docker image rm $REFERENCE_DATA_IMAGE_NAME
# Build Docker image
docker build \
  -t $REFERENCE_DATA_IMAGE_NAME \
  $tmp_build_context
# Remove temporary folder that served as a build context for Docker
rm -rf ${tmp_build_context}


