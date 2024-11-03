#!/bin/bash

set -a
source .env
set +a

pushd ${JUPYTER_DOCKER_PATH}

# Nom de l'image
JUPYTER_IMAGE_NAME="${JUPYTER_IMAGE_NAME:-jupyterlab_postgres}"

# Construction de l'image Docker
docker build -t $JUPYTER_IMAGE_NAME .

popd
