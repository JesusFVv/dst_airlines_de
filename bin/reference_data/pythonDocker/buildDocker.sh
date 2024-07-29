#!/bin/bash

# Set some variables
readonly container_name="python_docker_reference_data"
readonly image_name_python="python:3.11-alpine3.20"
readonly image_name_app="python_reference_data:latest"
readonly tmp_build_context="tmp_build_context"
readonly network_name="dst_network"  # Coming from docker-compose file implementing the postgres db

# Create a temporary folder that will serve as a build context for Docker
if [ -d ${tmp_build_context} ]; then
  rm -rf ${tmp_build_context}
fi
mkdir ${tmp_build_context}
cp * ${tmp_build_context} &>/dev/null
cp ../ingestRefData_01_referenceDataRaw.sql ${tmp_build_context} &>/dev/null
cp -r /home/ubuntu/dst_airlines_de/bin/common/ ${tmp_build_context}
mv ${tmp_build_context}/common/.dockerignore ${tmp_build_context}
cp -r /home/ubuntu/dst_airlines_de/src/project_deployment_postgres/*.txt ${tmp_build_context}
cp -r /home/ubuntu/dst_airlines_de/src/project_deployment_postgres/*.yml ${tmp_build_context}

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
docker run --volume /home/ubuntu/dst_airlines_de/data/referenceData:/home/ubuntu/dst_airlines_de/data/referenceData --network ${network_name} --name ${container_name} ${image_name_app}