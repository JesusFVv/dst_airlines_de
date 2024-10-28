#!/usr/bin/env bash
# Script to launch the docker compose with all services needed for the DST project
# Execute the script with command: bash launch_dst_services.sh

compose_down_dst_services_without_airflow() {
    pushd $SERVICES_DOCKER_COMPOSE_PATH
    docker compose down
    popd
}

set -a
source .env
set +a

set -e
compose_down_dst_services_without_airflow
set +e
