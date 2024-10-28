## Steps pour lancer tous les sevices

 - Si besoin, modifier la variable PROJECT_ABSOLUT_PATH dans le fichier .env à la racine du projet :

```shell
cd ~/dst_airlines_de
eval $(grep '^PROJECT_ABSOLUT_PATH=' .env)
echo "$PROJECT_ABSOLUT_PATH"
pwd
nano .env
```

 - RIEN A FAIRE/ Les services standard sont: Postgres, DBeaver, Nginx, RabbitMQ, PostgREST API, Metabase
 - Creer les images des services flight_schedules :

```shell
./lib/flights_scheduled/consumer/create_docker_image.sh
```
- Créer les images des services customer_flight_information :

```shell
./lib/customer_flight_info/consumer/docker_arrivals/create_docker_image.sh
./lib/customer_flight_info/consumer/docker_departures/create_docker_image.sh
```

- Déployer tous les services sauf Airflow `bash dst_services_compose_up.sh` :

```shell
./dst_services_compose_up.sh
```

- Déployer Airflow  :

```shell
./airflow_compose_up.sh
```

 - Restart le service NGINX

```shell
# docker exec -it nginx nginx -s reload
docker container restart nginx
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

## Metabase

[http://79.125.25.202:8000/metabase/](http://79.125.25.202:8000/metabase/)

```shell
cat ./src/docker_services/metabase/metabase_notes.md
grep '^POSTRES_READRE_PASS=' .env


```

## cloudbeaver

[http://79.125.25.202:8000/cloudbeaver/](http://79.125.25.202:8000/cloudbeaver/)

```shell
cat ./etc/cloudbeaver/dbeaver_credentials.md
grep '^POSTRES_READRE_PASS=' .env
```

 - SERVER INFORMATION :
   - Server Name : dst_airlines_de
   - Server UR : http://79.125.25.202:8000
   - admin : cbadmin
   - password : c*********4
 - New Connection / PostgreSQL :
   - Host : postgres_dst
   - Port : 5432
   - Database : dst_airlines_db
   - Connection name : dst_airlines_db@postgres_dst
   - User Name : dst_reader
   - User password : p*********r