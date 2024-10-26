## Steps pour lancer tous les sevices

- Modifier la variable PROJECT_ABSOLUT_PATH dans le fichier .env à la racine du projet
- RIEN A FAIRE/ Les services standard sont: Postgres, DBeaver, Nginx, RabbitMQ, PostgREST API, Metabase
- Creer les images des services flight_schedules
    - Executer le script lib/flight_schedules/consumer/create_docker_image.sh
- Créer les images des services customer_flight_information
    - Executer le script lib/customer_flight_info/consumer/docker_arrivals/create_docker_image.sh
    - Executer le script lib/customer_flight_info/consumer/docker_departures/create_docker_image.sh
- Run le fichier dst_service_compose_up.sh à la racine du projet. Ce script run les services hormis airflow mais ne s'occupe pas du tout de l'ingestion des data
- Le fichier airflow_compose_up.sh run le service airflow. Il est à la racine du projet.
- Restart le service NGINX
- Si install nouvelle Peupler la DB (je vais essayer de faire 3 SQL Dump de L1 et L2 et L3)
 - Pour le dump: pg_dump -U dst_designer -t l2.refdata_languages dst_airlines_db > /tmp/l2.refdata_languages.sql
 - Pour l'ingestion:
 



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
 
