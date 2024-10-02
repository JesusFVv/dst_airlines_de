# Airflow

## Install from docker compose

You will need the new version of [docker compose](https://docs.docker.com/compose/install/linux/#install-the-plugin-manually).

Then, follow the [instructions](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html) to install Airflow from docker compose.

Execute the following commands to launch Airflow **FOR THE FIRST TIME**. The steps done are:

- Creation of directories (dags, logs, plugins, config)
- Assigning permissions to directories
- Initialize airflow
- Finally, launch the docker compose up

```bash
#!/usr/bin/env bash
# execute as: src/docker/airflow/launch_airflow_composer.sh
set -a
.env  # AIRFLOW_PROJ_DIR & AIRFLOW_DOCKER_COMPOSE_DIR
set +a
echo -e "AIRFLOW_UID=$(id -u)" > .env
echo -e "AIRFLOW_PROJ_DIR=${AIRFLOW_PROJ_DIR}" >> .env
mkdir -p ${AIRFLOW_PROJ_DIR}/{dags,logs,plugins,config}
sudo chmod -R 777 ${AIRFLOW_PROJ_DIR}/{dags,logs,plugins,config}
pushd ${AIRFLOW_DOCKER_COMPOSE_DIR}
# If a docker compose for the Airflow service exists, remove it first
docker compose ls -a | grep airflow >& /dev/null && docker compose down
# Now launch the airflow service
docker compose up airflow-init
docker compose up -d
popd
```

## Clean the installation

```bash
# Run 
docker compose down --volumes --remove-orphans
# Remove airflow directory
rm -rf airflow
```

## Connect to the app

In the browser go to: http://63.35.176.208:8080/

user: airflow
pass: airflow

## Reverse proxy
https://airflow.apache.org/docs/apache-airflow/stable/howto/run-behind-proxy.html
    environment:
      AIRFLOW__WEBSERVER__BASE_URL: http://localhost:8080/airflow/

Change the base_url in the file: /opt/airflow/airflow.cfg
base_url = http://localhost:8080/airflow/

maybe this [source](https://www.restack.io/docs/airflow-faq-howto-run-behind-proxy-01)

In order to be able to reverse proxy from nginx to airflow we need to add the following environmental variables in the docker compose file:
  - AIRFLOW__WEBSERVER__BASE_URL: 'http://0.0.0.0:8080/airflow'  # Needed only for http connections
  - AIRFLOW__WEBSERVER__ENABLE_PROXY_FIX: 'true'  # Needed only to ensure generating the correct URL schema behind TLS-terminating proxy (e.g., https://)
  - Additionally, in the nginx configuration file, we need to add the line `proxy_set_header   X-Forwarded-Proto    "https";` in the services block

  ```nginx
  location /airflow/ {
    proxy_pass http://airflow-airflow-webserver-1:8080;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";   
    proxy_set_header   X-Forwarded-Proto    "https";
  }
  ```
  