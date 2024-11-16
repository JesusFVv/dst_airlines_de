# DST Airlines
Project for the Data Engineer Program of [DataScientest](https://datascientest.com/#).

The objective is to create and deploy a system able to source flight data, transform it and put it at disposition of the end users (ex. field, data analyst or data scientists).

## Data sources

![image](https://github.com/user-attachments/assets/4a599821-517e-4e4a-b169-1c5206b9823c)

1. **Reference Data**: airports, airlines, aircrafts, cities, countries. Slowly changing dimensions, but modeled as constant. Extracted only once.
2. **Departures**: actual departures from a given airport and a time range. Constant dimension as describes past data. Every day we extract the J-1 departures (300 queries/day).
3. **Arrivals**: actual arrivals to a given airport and a time range. Constant dimension as describes past data. Every day we extract the J-1 arrivals (300 queries/day).
4. **Future flights**: flights scheduled for a given route and day. Slowly changing dimension, modeled as constant. Every day we extract the J+90 scheduled flights (2500 queries/day).
5. **Bird strikes**: airplane events originated by a bird strike. Constant dimension as describes past data. Extracted only once.

## Data Life Cycle

![image](https://github.com/user-attachments/assets/172bd673-e703-48ab-a2a0-e3d7b2807802)

### Sources
- Sources 2, 3 and 4 are Lufthansa API endpoitns,  with responses in JSON format that need to be requested daily to get the udpated flight informations.
- Source 1 is another Luthansa API endpoint, with response in JSON format, and this is requestes at the beginning to build the base for the reference data.
- Source 5 is a web site (avherald.com), the information is in HTML format and is recovered only once. With the events going up to mid 2024.

### Ingestions

Different pipelines styles have been developped. In general all the data collected from the different sources is ingested in batch.

#### Pipeline for dynamic sources

For the sources 2, 3 and 4, there is an automated workflow to ingest the newly generated data in a daily basis. Each day for the 2 and 3, we ingest the previous day flights (J-1) and for the 4, we ingest a new day in the future defined as J+90 days.

For the ingestion architecture we chose to implement a [Work Queue](https://www.rabbitmq.com/tutorials/tutorial-two-python) using Python and RabbitMQ.
- A producer will generate daily, for each endpoint, the new URLs to query and send them to the endpoint's queue.
- There is a queue for each one of the endpoints and the information is persisted on disk.
- A consumer is continuously listening on the other side of the queue, and will grab a new endpoint's URL, query de information on the Internet and store it into the database in raw format, in the l1 layer

This micro-services architecture has the following advantages from a monolitic pipeline:
- Simplifies the bookkeping of endpoint's URLs for the day, using the queue. Geneartion of endpoint urls and the consumtion of their data is asyncrhonous (Fast vs Slow process), and they are persisted to disk. 
- Avoids data loss. If a consumer fails for an uncaught exception, the endpoint is not lost, it goes back to the queue and it will be retried.
- Allows to simplify the overall custom code for the ingestion pipeline, in particular in how to deal with exceptions if the query failed.
- Allows for an easy parallelization of consumers. We could spawn as many consumer as we wish depending on the amount of endpoints to query, simply by using the "replica" option in the docker compose file.

#### Pipeline for static sources

On the other hand, for the source 1 and 5 we did a one time extraction and ingestion worflow.
For 1, the reference data is extracted using a bash script, loaded to a stagging area in the local filesystem and ingested in the data base L1, in JSON format.
For the 5, a csv file was ingeted to L1 with more than 2k events.

### Storage

The storage component is a data wharehouse composed by two Postgresql servers. The first is composed of 3 schemas, L1, L2 and L3, it is used to store, normalize and create business value. And the second server has a graph DB with the scheduled flights information, to be able to calculate flight routes efficiently.

In L1 the data lands in the original format, raw. For example, JSON for the most part and tabular for the sources 4 and 5. It is a pseudo stagging zone, used primarily for keeping the maximum amount of the original data without tranformations and filters.

Then, there are two types of automated pipelines that tranform and load the data to the second layer L2, where the data is higly normalized:
- One based on python and orchestrated with airflow, to combine and normalize the data comming from sources 2 and 3.
- and another one based on SQL triggers deploied directly in the server to also normalize the data comming from the source 4. (no need of external orchestration).

In the L2 the structure is highly normalized (almost to the [3NF](https://en.wikipedia.org/wiki/Third_normal_form)), which allow us to:
- Eliminate data redundancy by creating a logic Entity Relationship Schema.
- Improves overall data quality (using constraints and foreign keys relationship between tables for example)
- Improves the trust we have in the data.

The L3, used as our [Semantic Layer](https://en.wikipedia.org/wiki/Semantic_layer), it contains the bussines logic developped with the field experts and is used to solve the use cases. Thus it contains wide, aggregated tables, which are ready for the consumtion by the business or the data scientist.

Finally the GraphDB, transforms the tabular data about the flight routes stored in L3 into a graph. This allow us to be able to calculate routes between an airport A and B, with a maximum number of flights in between. In a traditional DB (as L3) this task put a lot of pressure due to its recursive nature, and in our cause was taking down the DB. But with the graph DB its fast and efficient.

Next picture makes a zoom in the storage part of our architecture, to show the automatisation between the databases (or schemas in postgresql).


### Consumption

The image below shows the services that have been deploied to allow the stakeholders to access the data in various ways.
Nginx is used as reverse-proxy to centralize and secure all the connections.

- Dashboarding with *Metabase*
- API with *PostgREST*
- Data base tool with *CloudBeaver*
- Notebooks with *JupyterHub*
- Orchestration with *Airflow*

Note: The HTTPS services have been disabled in the Nginx configuration for ease of deployment (no need of SSL certificates). But the nginx config files are prepared to take it into account. (var/nginx/conf.d/dst_apps.conf)

![image](https://github.com/user-attachments/assets/bef7c63c-ce09-418f-be11-dfa081d6a92e)

## Deploy the project

The steps and settings needed to deploy the project in a new environment are detailed below:

- Clone the project from GitHub at https://github.com/JesusFVv/dst_airlines_de.git
- Checkout to last tag (ex. v2.2-lw)
- Set the value of the variable **PROJECT_ABSOLUT_PATH** in the **.env** file, to the absolute path of the folder.
- Create the custom images needed for the project
```shell
# Flight Schedules Producer
./lib/flights_scheduled/consumer/create_docker_image.sh
# Customer Flight Information Producer
./lib/customer_flight_info/consumer/docker_arrivals/create_docker_image.sh
./lib/customer_flight_info/consumer/docker_departures/create_docker_image.sh
# Customer Flight Information autoloader L1 to L2
./lib/customer_flight_info/l2_loading_incremental/create_docker_image.sh
# JupyterHub
./src/docker_services/jupyterhub/create_docker_image.sh
```
- Unzip the backup files for both databases. They will be used by docker at initialisation.
```shell
# Unzip the DB backup
gunzip -c var/db_dumps/20241113_212742_dst_airlines_db_dump.sql.gz > src/dst_docker_services/postgres/2_schemas_tables_and_data.sql
# Unzip the Graph DB backup
gunzip -c var/db_dumps/graph_db/20241113_190854_dst_graph_db_dump.sql.gz > src/docker_services/postgres_age/docker_entrypoint_scripts/2_schemas_tables_and_data.sql
# And comment the line 23: -- CREATE SCHEMA ag_catalog;
```
- Run the script that executes the docker compose up files
```shell
# Launch all services but airflow
./dst_services_compose_up.sh
# Launch Airflow only
./airflow_compose_up.sh
```
- Update DB of the Metabase container
```shell
# Stop Metabase container
# Overwrite the containers DB file (which is a managed docker volume)
sudo cp -r var/metabase/data/metabase.db/. /var/lib/docker/volumes/metabase-data/_data/metabase.db/
# Start Metabase container
```
- Restart Nginx
- In Airflow Create a ssh connection to the VM
```log
Connection id: WSL_Home
Host: 34.248.4.187
Username: ubuntu
Extra: {"private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIIEowI......mCf23\n-----END RSA PRIVATE KEY-----"}
```

