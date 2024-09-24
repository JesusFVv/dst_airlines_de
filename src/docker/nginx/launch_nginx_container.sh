#!/usr/bin/env bash
# execute it with command: bash src/docker/nginx/launch_nginx_container.sh

set -a
source .env
set +a

CONTAINER_NAME=nginx
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
docker run --name $CONTAINER_NAME \
-v ${PROJECT_ABSOLUT_PATH}/var/nginx/conf.d:/etc/nginx/conf.d:ro \
-v ${PROJECT_ABSOLUT_PATH}/var/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
-v ${PROJECT_ABSOLUT_PATH}/etc/ssl/certs/dst_vm.crt:/etc/nginx/ssl/dst_vm.crt:ro \
-v ${PROJECT_ABSOLUT_PATH}/etc/ssl/certs/dst_vm.key:/etc/nginx/ssl/dst_vm.key:ro \
--network dst_network -p 8080:80 -p 8085:443 --restart unless-stopped \
-d nginx

