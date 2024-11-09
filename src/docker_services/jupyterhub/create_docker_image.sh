#!/usr/bin/env bash
# Execute the script with command:
#   bash src/docker_services/jupyterhub/create_docker_image.sh
set -a
source .env
set +a
pushd ${JUPYTERHUB_DOCKER_PATH}
docker build -t jupyterhub .
popd
