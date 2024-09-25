# Airflow

## Install from docker compose

First install the new version of [docker compose](https://docs.docker.com/compose/install/linux/#install-the-plugin-manually).

Then, follow the [instructions](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html) to install from docker compose.


```bash
# cd src/docker/airflow
set -a
../../../.env
set +a
AIRFLOW_PROJ_DIR=${PROJECT_ABSOLUT_PATH}/var/airflow
echo -e "AIRFLOW_UID=$(id -u)" > .env
echo -e "AIRFLOW_PROJ_DIR=${AIRFLOW_PROJ_DIR}" >> .env
pushd ${AIRFLOW_PROJ_DIR}
mkdir -p ./dags ./logs ./plugins ./config
popd
# sudo chmod -R 777 logs/
# sudo chmod -R 777 dags/
# sudo chmod -R 777 plugins/
docker compose up airflow-init
docker compose up -d
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

## REverse proxy
https://airflow.apache.org/docs/apache-airflow/stable/howto/run-behind-proxy.html
    environment:
      AIRFLOW__WEBSERVER__BASE_URL: http://localhost:8080/airflow/

Change the base_url in the file: /opt/airflow/airflow.cfg
base_url = http://localhost:8080/airflow/

maybe this [source](https://www.restack.io/docs/airflow-faq-howto-run-behind-proxy-01)

added the env vars in docker compose:
  - AIRFLOW__WEBSERVER__BASE_URL: 'http://0.0.0.0:8080/airflow'
  - AIRFLOW__WEBSERVER__ENABLE_PROXY_FIX: 'true' --> Not needed

