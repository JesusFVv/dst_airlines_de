#!/bin/bash

# Set some variables
readonly container_name="python_extract_data"
readonly image_name_python="python:3.11-alpine3.20"
readonly image_name_app="python_extract_customer_flight_info:latest"
readonly tmp_build_context="tmp_build_context"

# Create a temporary folder that will serve as a build context for Docker
if [ -d ${tmp_build_context} ]; then
  rm -rf ${tmp_build_context}
fi
mkdir ${tmp_build_context}
cp * ${tmp_build_context} &>/dev/null
cp -r input/ ${tmp_build_context}
cp -r /home/ubuntu/dst_airlines_de/bin/common/ ${tmp_build_context}
rm ${tmp_build_context}/common/database.ini
mv ${tmp_build_context}/common/.dockerignore ${tmp_build_context}

# Remove container - it might be there from a previous run
docker container inspect ${container_name} &>/dev/null && docker container rm ${container_name}
# Remove images - they might be there from a previous build
docker image inspect ${image_name_python} &>/dev/null && docker image rm ${image_name_python}
docker image inspect ${image_name_app} &>/dev/null && docker image rm ${image_name_app}
# Build Docker image
docker build -t ${image_name_app} ${tmp_build_context}
# Remove temporary folder that served as a build context for Docker
rm -rf ${tmp_build_context}
# Run Docker
docker run --volume /home/ubuntu/dst_airlines_de/data/customerFlightInfo:/home/ubuntu/dst_airlines_de/data/customerFlightInfo --name ${container_name} ${image_name_app}
