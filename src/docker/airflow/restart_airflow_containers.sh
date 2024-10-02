#!/usr/bin/env bash
# execute as: src/docker/airflow/start_airflow_containers.sh
set -a
source .env  # AIRFLOW_DOCKER_COMPOSE_DIR
set +a

pushd ${AIRFLOW_DOCKER_COMPOSE_DIR}
# docker compose ls -a | grep airflow >& /dev/null && docker compose up -d
if docker compose ls -a | grep airflow | grep "exited(7)" >& /dev/null; then
    docker compose up -d
else
    docker compose ls -a
    echo "WARNING: airflow containers either are already running or were not initialized"
fi
popd
