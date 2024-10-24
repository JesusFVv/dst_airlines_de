#!/usr/bin/env bash
# Script to launch the docker compose with all services needed for the DST project
# Execute the script with command: bash dst_services_compose_up.sh

init_dst_services_without_airflow() {
    pushd $SERVICES_DOCKER_COMPOSE_PATH
    docker compose up -d
    popd
}

set -a
source .env
set +a

set -e
init_dst_services_without_airflow
set +e
