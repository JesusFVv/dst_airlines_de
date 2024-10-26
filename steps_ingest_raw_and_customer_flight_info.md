## Steps pour lancer tous les sevices

- Modifier la variable PROJECT_ABSOLUT_PATH dans le fichier .env à la racine du projet
- RIEN A FAIRE/ Les services standard sont: Postgres, DBeaver, Nginx, RabbitMQ, PostgREST API, Metabase
- Creer les images des services flight_schedules
    - Executer le script `bash lib/flight_scheduled/consumer/create_docker_image.sh`
- Créer les images des services customer_flight_information
    - Executer le script `bash lib/customer_flight_info/consumer/docker_arrivals/create_docker_image.sh`
    - Executer le script `bash lib/customer_flight_info/consumer/docker_departures/create_docker_image.sh`
- Déployer tous les services sauf Airflow `bash dst_services_compose_up.sh`
- Déployer Airflow `bash airflow_compose_up.sh`
- Restart le service NGINX
- Si install nouvelle Peupler la DB (je vais essayer de faire 3 SQL Dump de L1 et L2 et L3)
 - Pour le dump: pg_dump -U dst_designer -t l2.refdata_languages dst_airlines_db > /tmp/l2.refdata_languages.sql
 - Pour l'ingestion:

A LA FIN DU DEPLOYEMENT LA DB EST REMPLIE (l1, l2 et l3), pour pouvoir faire visuelles!!!!



## Steps pour populer les tables
 
1. cd lib/reference_data/full_ingest

./create_docker_image.sh
./launch_docker_container.sh
 
2. cd lib/customer_flight_info/l1_loading

./build_docker_image.sh
./run_docker_container.sh
 
3. cd lib/customer_flight_info/l2_loading

./build_docker_image.sh
./run_docker_container.sh
 
