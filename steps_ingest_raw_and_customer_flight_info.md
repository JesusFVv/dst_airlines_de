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

- Decompresser le dump de la DB

```shell
gunzip -c src/dst_docker_services/postgres/2_schemas_tables_and_data.sql.gz > src/dst_docker_services/postgres/2_schemas_tables_and_data.sql
```

- Creer les images des services flight_schedules :

```shell
./lib/flights_scheduled/consumer/create_docker_image.sh
```
- Créer les images des services customer_flight_information :

```shell
./lib/customer_flight_info/consumer/docker_arrivals/create_docker_image.sh
./lib/customer_flight_info/consumer/docker_departures/create_docker_image.sh
```

- ⚠️ A faire une seule fois sur la VM : créer le certificat SSL pour nginx en suivant la [documentation Create SSL Certificate](src/docker_services/nginx/nginx_notes.md#create-ssl-certificate).

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

## Arrêt des consumers

- Pour travailler sur les données de la VM, il est possible d'arrêter les consumers :

```shell
docker stop dst_docker_services-flight_schedules_consumer-1 \
       dst_docker_services-flight_schedules_consumer-2 \
	   dst_docker_services-flight_schedules_consumer_c-1 \
	   dst_docker_services-customer_flight_information_arrivals_consumer-1 \
	   dst_docker_services-customer_flight_information_departures_consumer-1 \
	   dst_docker_services-flight_schedules_consumer_c-2
```
 
## Steps pour populer les tables

- A faire uniquement si les base ne sont pas peuplées avec le dump (**avant v1.0-lw**)
 
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

## Lancer le docker jupyter

- Il est possible de lancer un jupyter lab ponctuellement pour répondre a un besoin de développement :

### Création du docker

```shell
./src/docker_services/jupyter/create_docker_image.sh
```

### Démarrage du docker

```shell
./src/docker_services/jupyter/launch_docker_container.sh
```

### Exploitation

L'image est exposée sur le port **8346** :

```shell
cat .env | grep JUPYTER_PORT
```

Création du tunnel pour accéder à **Nginx** et **Jupyter** depuis Windows ou WSL :

```shell
ssh -i "~/cle/data_enginering_machine.pem" -L 8000:localhost:8000 -L 8346:localhost:8346 ubuntu@79.125.25.202
```

Il est ensuite possible de créer des notebooks ici : [http://79.125.25.202:8346/lab/](http://79.125.25.202:8346/lab/)

Les notebooks créés sont stockés en local ici : `./src/docker_services/jupyter/notebooks/`

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
   - Server URL : http://79.125.25.202:8000
   - admin : cbadmin
   - password : c*********4
 - New Connection / PostgreSQL :
   - Host : postgres_dst
   - Port : 5432
   - Database : dst_airlines_db
   - Connection name : dst_airlines_db@postgres_dst
   - User Name : dst_reader
   - User password : p*********r
