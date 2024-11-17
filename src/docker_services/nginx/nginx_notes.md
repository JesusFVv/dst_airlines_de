# NGINX

In order to secure the acces to the different http applications we use a reverse proxy, ideally with https acces. This allow us to not expose the applications directly on the internet.

## Launch NGINX

### With Docker

Execute following commands.

```bash
#!/usr/bin/env bash
# execute it with command: bash src/docker/nginx/launch_nginx_container.sh
# -p 8000:80 -p 8085:443 \  # HTTP and HTTPS connections
# -p 5433:5433 \  # PostgreSQL TCP connection reverse proxy
# --add-host host.docker.internal:host-gateway \ Adds the docker host gateway IP to the DNS host.docker.internal, so it would be available inside the container to be used in the nginx conf to reverse proxy to the superset nginx container at port 9000. (ex. host.docker.internal = 172.17.0.1 (docker0 gateway IP `ip addr show docker0`))

set -a
source .env  # .env file is at the projcet ROOT and contains the value of the variable PROJECT_ABSOLUT_PATH.
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
```

## Configuration

Configuration files needed for the NGINX service are located in Host in `PROJECT_DIR/var/nginx`.

The configuration files needed for our case are:

- `var/nginx/nginx.conf` - main configuration file for NGINX service. Define the blocks HTTP and STREAM.
- `var/nginx/conf.d/dst_apps.conf` - define the HTTP servers for our applications.
- `var/nginx/stream.conf.d/postgresql_reads.conf` - define the STREAM servers for the postgresql database.

To reload the NGINX configuration, send the HUP signal to Docker:

```bash
docker kill -s HUP $CONTAINER_NAME
```

## Logs

```bash
docker logs -f nginx
```

## Create SSL certificate

SSL certificate are needed for the HTTPS acces. To create a new certificate, run the following commands. But, those certificates are not issued by any recognize autority, so we still need to say to the browser that we trust the certificate manually.

```bash
# In project root path create the SSL certificates
sudo openssl req -newkey rsa:4096 \
-x509 \
-sha256 \
-days 3650 \
-nodes \
-out dst_vm.crt \
-keyout dst_vm.key \
-subj "/C=FR/ST=Paris/L=Paris/O=SAE/OU=IT Department/CN=server dst project"
# Move the ssl certificates to folder
mkdir -p etc/ssl/certs
sudo mv dst_vm.* etc/ssl/certs

```

## Check connection to the apps

```bash
# HTTP version, work in browser and CLI
curl --fail -I http://{VM-IP}:8000/metabase/
curl --fail -I http://{VM-IP}:8000/cloudbeaver/
curl --fail -I http://{VM-IP}:8000/airflow/
curl --fail -I http://{VM_IP}:8000/  # Superset
curl --fail -I http://{VM_IP}:8000/postgrest_api/
curl --fail -I http://{VM_IP}:8000/jupyterlab/

# The HTTPS version work in CLI but not in the browser of the SAE PC
curl --insecure --fail -I https://{VM-IP}:8085/metabase/
curl --insecure --fail -I https://{VM-IP}:8085/cloudbeaver/
curl --insecure --fail -I https://{VM-IP}:8085/airflow/
curl --insecure --fail -I https://{VM_IP}:8000/postgrest_api/
```

## Acces to the apps with the browser

CloudBeaver: http://{VM-IP}:8000/cloudbeaver/
Metabase: http://{VM-IP}:8000/metabase/
Airflow: http://{VM-IP}:8000/airflow/


## Configuration needed to allow some service to be reverse proxyed with NGINX

Adaptations of the base URL needed for the following applications, in order to be able to reverse proxy them with Nginx:

### In Cloudbeaver

[Configuring nginx for cloudbeaver](https://github.com/dbeaver/cloudbeaver/wiki/CloudBeaver-and-Nginx)

[Editing RootURI](https://github.com/dbeaver/cloudbeaver/issues/279)

The base URL for CloudBeaver have been changed to be able to acces it with Nginx. It is done with the environment variable `CLOUDBEAVER_ROOT_URI`. This will tell Cloudbeaver to add its value at the end of every URL.

In the docker compose we have declared under the dbeaver service the environment variable:

```yaml
services:
  ...
  dbeaver:
    ...
    environment:
      CLOUDBEAVER_ROOT_URI: /cloudbeaver
      ...
    ...
```

And the nginx conf

```conf
server {
  ...
    location /cloudbeaver/ {
        proxy_pass http://dbeaver:8978;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
  ...
}
```

### In Airflow


### In Superset

Only change, is to change in the docker compose file the exposed port for it own nginx, from 80 to 9000.

#### TCP connection to the PostgreSQL DB

We create an Stream block in NGINX to be able to create TCP connections to the PostgreSQL DB from within the
superset local network. The configuration is in `var/nginx/stream.conf.d`

Changes have been made in pg_hba.conf file in order to only allow connections from internal docker IPv4 addresses: `host all all 172.0.0.0/8 scram-sha-256  # Acces to all the IPv4 addresses of the docker containers`


