## Steps pour lancer tous les sevices

 - Modifier la variable PROJECT_ABSOLUT_PATH dans le fichier .env à la racine du projet

```shell
cd ~/dst_airlines_de
eval $(grep '^PROJECT_ABSOLUT_PATH=' .env)
echo "$PROJECT_ABSOLUT_PATH"
pwd
nano .env
```

 - RIEN A FAIRE/ Les services standard sont: Postgres, DBeaver, Nginx, RabbitMQ, PostgREST API, Metabase
 - Creer le fichiers secrets :

```shell
nano ./lib/flights_scheduled/extraction/.dlt/secrets.toml

```
   - Contenu (remplacer le password) :
    - Executer le script `bash lib/flight_scheduled/consumer/create_docker_image.sh`
- Créer les images des services customer_flight_information
    - Executer le script `bash lib/customer_flight_info/consumer/docker_arrivals/create_docker_image.sh`
    - Executer le script `bash lib/customer_flight_info/consumer/docker_departures/create_docker_image.sh`
- Déployer tous les services sauf Airflow `bash dst_services_compose_up.sh`
- Déployer Airflow `bash airflow_compose_up.sh`

```text
[source.lufthansaAPI]
acces_token_url = "https://api.lufthansa.com/v1/oauth/token"
flight_schedules_cliend_id = "xpavg4z64mqt5wyystzh6953k"
flight_schedules_cliend_secret = "U724kV9JW2"

[destination.postgres.credentials]
database = "dst_airlines_db"
schema = "l1"
username = "dst_designer"
password = "V******************V"
# host = "172.17.0.1"  # Docker IP Gateway
host = "postgres_dst"
# port = 5433
port = 5432
connect_timeout = 15
```

 - Creer les images des dockers :

```shell
chmod u+x ./lib/flights_scheduled/producer/create_docker_image.sh
./lib/flights_scheduled/producer/create_docker_image.sh

chmod u+x ./lib/flights_scheduled/extraction/create_docker_image.sh
./lib/flights_scheduled/extraction/create_docker_image.sh

chmod u+x ./lib/customer_flight_info/consumer/docker_arrivals/create_docker_image.sh
./lib/customer_flight_info/consumer/docker_arrivals/create_docker_image.sh

chmod u+x ./lib/customer_flight_info/consumer/docker_departures/create_docker_image.sh
./lib/customer_flight_info/consumer/docker_departures/create_docker_image.sh


```

 - Run `fichier dst_service_compose_up.sh` à la racine du projet. Ce script run les services hormis airflow mais ne s'occupe pas du tout de l'ingestion des data

```shell
chmod u+x dst_services_compose_*
./dst_services_compose_up.sh

```

 - Run `fichier airflow_compose_up.sh` run le service airflow. Il est à la racine du projet.

```shell
./airflow_compose_up.sh
```

 - Restart le service NGINX

```shell
docker exec -it nginx nginx -s reload

```

 - Si install nouvelle Peupler la DB (je vais essayer de faire 3 SQL Dump de L1 et L2 et L3)
   - Pour le dump: pg_dump -U dst_designer -t l2.refdata_languages dst_airlines_db > /tmp/l2.refdata_languages.sql
   - Pour l'ingestion:
 



## Steps pour populer les tables
 
 1. **reference_data**

```shell
./lib/reference_data/full_ingest/create_docker_image.sh
./lib/reference_data/full_ingest/launch_docker_container.sh

```
 
 2. **customer_flight_info/l1_loading**

```shell
./lib/customer_flight_info/l1_loading/build_docker_image.sh
./lib/customer_flight_info/l1_loading/run_docker_container.sh

```
 
 3. **lib/customer_flight_info/l2_loading**

```shell
./lib/customer_flight_info/l2_loading/build_docker_image.sh
./lib/customer_flight_info/l2_loading/run_docker_container.sh

``` 
