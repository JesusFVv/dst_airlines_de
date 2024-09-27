#!/usr/bin/env bash
# execute it with command: bash src/docker/nginx/launch_nginx_container.sh
# -p 80:80 -p 8085:443 \  # HTTP and HTTPS connections
# -p 5433:5433 \  # PostgreSQL TCP connection reverse proxy
# --add-host host.docker.internal:host-gateway \ Adds the docker host gateway IP to the DNS host.docker.internal, so it would be available inside the container to be used in the nginx conf to reverse proxy to the superset nginx container at port 9000

set -a
source .env
set +a

CONTAINER_NAME=nginx
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
docker run --name $CONTAINER_NAME \
-v ${PROJECT_ABSOLUT_PATH}/var/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
-v ${PROJECT_ABSOLUT_PATH}/var/nginx/conf.d:/etc/nginx/conf.d:ro \
-v ${PROJECT_ABSOLUT_PATH}/var/nginx/stream.conf.d:/etc/nginx/stream.conf.d:ro \
-v ${PROJECT_ABSOLUT_PATH}/etc/ssl/certs/dst_vm.crt:/etc/nginx/ssl/dst_vm.crt:ro \
-v ${PROJECT_ABSOLUT_PATH}/etc/ssl/certs/dst_vm.key:/etc/nginx/ssl/dst_vm.key:ro \
--add-host host.docker.internal:host-gateway \
--network dst_network -p 8000:80 -p 8085:443 -p 5433:5433 \
--restart unless-stopped \
-d nginx


