#!/usr/bin/env bash
# Execute the script with command:
#   bash lib/customer_flight_info/l2_loading_incremental/create_docker_image.sh
set -a
source .env
set +a
pushd ${CUSTOMER_FLIGHT_INFO_L2_INCREMENTAL_LOADING_DOCKER_PATH}
docker build -t dst_customer_flight_information_l2_incremental_loading -f Dockerfile ${PROJECT_ABSOLUT_PATH}/lib
popd
