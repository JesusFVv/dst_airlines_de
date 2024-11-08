#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Variables
JUPYTER_IMAGE_NAME="${JUPYTER_IMAGE_NAME:-jupyterlab_postgres}"
PROJECT_NETWORK_1="${PROJECT_NETWORK_1:-dst_network}"  # Par défaut si non défini
JUPYTER_DATA_CONTAINER_NAME="${JUPYTER_DATA_CONTAINER_NAME:-jupyter_data_container}"  # Par défaut si non défini
LOCAL_NOTEBOOK_DIR="${JUPYTER_DOCKER_PATH}/notebooks"  # Dossier local pour les notebooks

# Création du dossier local si inexistant
mkdir -p "$LOCAL_NOTEBOOK_DIR"

# Lancer le conteneur
docker run -d \
  --name $JUPYTER_DATA_CONTAINER_NAME \
  --network $PROJECT_NETWORK_1 \
  -p ${JUPYTER_PORT}:${JUPYTER_PORT} \
  -v "$LOCAL_NOTEBOOK_DIR":/home/jovyan/dst_airlines_de \
  $JUPYTER_IMAGE_NAME

