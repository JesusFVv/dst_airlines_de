#!/usr/bin/env bash
# execute as: src/docker/airflow/launch_airflow_composer_first_time.sh
set -a
source .env  # AIRFLOW_PROJ_DIR & AIRFLOW_DOCKER_COMPOSE_DIR
set +a

docker_compose_down() {
    pushd ${AIRFLOW_DOCKER_COMPOSE_DIR}
    docker compose down
    popd
}

docker_compose_init_up() {
    pushd ${AIRFLOW_DOCKER_COMPOSE_DIR}
    docker compose up airflow-init
    docker compose up -d
    popd
}

if docker compose ls -a | grep airflow >& /dev/null; then
    # Service existed already (we keep the mounted volumes)
    docker_compose_down
else
    echo -e "AIRFLOW_UID=$(id -u)"
    echo -e "AIRFLOW_PROJ_DIR=${AIRFLOW_PROJ_DIR}"
    mkdir -p ${AIRFLOW_PROJ_DIR}/{dags,logs,plugins,config}
    sudo chmod -R 777 ${AIRFLOW_PROJ_DIR}/{dags,logs,plugins,config}
fi
# Initialize and launch the Ariflow Service
docker_compose_init_up
