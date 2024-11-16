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

In the browser go to: http://IP:8080/

user: airflow
pass: airflow

## Reverse proxy with NGINX
Sources:
- [Source](https://airflow.apache.org/docs/apache-airflow/stable/howto/run-behind-proxy.html)
- And this [Source 2](https://www.restack.io/docs/airflow-faq-howto-run-behind-proxy-01)

In order to be able to reverse proxy from nginx to airflow we need to add the following environmental variables in the docker compose file:
  - AIRFLOW__WEBSERVER__BASE_URL: 'http://0.0.0.0:8080/airflow'  # Needed only for http connections. Updates the value in */opt/airflow/airflow.cfg*
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
  
## Use DockerOperator

[Follow this guide](https://medium.com/apache-airflow/utilizing-dockeroperator-in-airflow-to-run-containerized-applications-in-data-engineer-projects-f596df26ea83)

DockerOperator allows Airflow (even if Airflow is running inside a Docker container) to use the docker socket to launch new containers, **as if we were launching them from the host**. (ex. volumens mount paths are those for the Host)

Steps:

- In the docker compose I declared an additional volume in the *airflow-common* service:
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:rw
```
- Also, I had to modify the permissions of the docker.sock (Not Great because anybody has now access to the docker.sock)
```bash
sudo chmod 666 /var/run/docker.sock
# Original privileges are 660 user:root and group:docker
```
- DockerOperator works now, here an example. The DockerOperator instructions, are the same as we will use for launching the container from the Host terminal.

```python
from airflow.decorators import dag
from airflow.providers.docker.operators.docker import DockerOperator
from docker.types import Mount
from pendulum import datetime


@dag(start_date=datetime(2024, 10, 19), schedule=None, catchup=False)
def airflow_docker_operator():

    flight_schedules_producer = DockerOperator(
        task_id='flight_schedules_producer',
        image='dst_flight_schedules_producer:latest',
        container_name='flight_schedules_producer',
        docker_url='unix://var/run/docker.sock',
        network_mode='dst_network',
        mount_tmp_dir=False,
        auto_remove='success',
        environment={
            'AIRPORTS_FILE_PATH': '/usr/src/app/data/airports.csv',
            'RABBITMQ_HOST': 'rabbitmq',
            'RABBITMQ_PORT': '5672',
            'FLIGHT_SCHEDULES_CHANNEL': 'flight_schedules',
            'LOG_FILE_PATH': '/usr/src/app/log',
        },
        mounts=[
            Mount(source='/home/ubuntu-user1/prj/dst_airlines_project/dst_airlines_de/data/airports/airports.csv', target='/usr/src/app/data/airports.csv', type="bind"),
            Mount(source='/home/ubuntu-user1/prj/dst_airlines_project/dst_airlines_de/var/flight_schedules/log/producer', target='/usr/src/app/log', type="bind"),
        ]        
    )
      
    flight_schedules_producer


airflow_docker_operator()
```
