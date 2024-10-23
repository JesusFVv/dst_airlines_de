#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Set a variable for temporary build context folder
readonly tmp_build_context=${CUSTOMER_FLIGHT_INFO_L1_LOADING_PATH}/tmp_build_context

# Create a temporary folder that will serve as a build context for Docker
if [ -d ${tmp_build_context} ]; then
  rm -rf ${tmp_build_context}
fi
mkdir ${tmp_build_context}

cp ${CUSTOMER_FLIGHT_INFO_L1_LOADING_PATH}/{Dockerfile,requirements.txt,*.py} ${tmp_build_context}
mkdir ${tmp_build_context}/common
cp ${PROJECT_ABSOLUT_PATH}/lib/common/utils.py $_
cp ${PROJECT_ABSOLUT_PATH}/lib/common/.dockerignore ${tmp_build_context}

# Remove container - it might be there from a previous run
docker container inspect ${CUSTOMER_FLIGHT_INFO_L1_LOADING_CONTAINER_NAME} &>/dev/null && docker container rm ${CUSTOMER_FLIGHT_INFO_L1_LOADING_CONTAINER_NAME}
# Remove image - it might be there from a previous build
docker image inspect ${CUSTOMER_FLIGHT_INFO_L1_LOADING_IMAGE_NAME} &>/dev/null && docker image rm ${CUSTOMER_FLIGHT_INFO_L1_LOADING_IMAGE_NAME}
# Build Docker image
docker build -t ${CUSTOMER_FLIGHT_INFO_L1_LOADING_IMAGE_NAME} ${tmp_build_context}
# Remove temporary folder that served as a build context for Docker
rm -rf ${tmp_build_context}
