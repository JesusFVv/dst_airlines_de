# DST Airlines
Project Data Engineer.

## Data sources

![image](https://github.com/user-attachments/assets/4a599821-517e-4e4a-b169-1c5206b9823c)

1. **Reference Data**: airports, airlines, aircrafts, cities, countries. Slowly changing dimensions, but modeled as constant. Extracted only once.
2. **Departures**: actual departures from a given airport and a time range. Constant dimension as describes past data. Every day we extract the J-1 departures (300 queries/day).
3. **Arrivals**: actual arrivals to a given airport and a time range. Constant dimension as describes past data. Every day we extract the J-1 arrivals (300 queries/day).
4. **Future flights**: flights scheduled for a given route and day. Slowly changing dimension, modeled as constant. Every day we extract the J+90 scheduled flights (2500 queries/day).
5. **Bird strikes**: airplane events originated by a bird strike. Constant dimension as describes past data. Extracted only once.


## Data Life Cycle

![image](https://github.com/user-attachments/assets/84bcadcc-60c0-405c-94d4-05e8f8b9f097)


### Sources
- Sources 2, 3 and 4 are Lufthansa API endpoitns,  with responses in JSON format that need to be requested daily to get the udpated flight informations.
- Source 1 is another Luthansa API endpoint, with response in JSON format, and this is requestes at the beginning to build the base for the reference data.
- Source 5 is a web site (avherald.com), the information is in HTML format and is recovered only once. With event going up to mid 2024.

### Ingestions

Different pipelines styles have been developped. In general all the data collected from the different sources is ingested in batch.

### Pipeline for sources 2, 3 and 4

For the sources 2, 3 and 4, there is an automated workflow to ingest the newly generated data in a daily basis.

Each day for the 2 and 3, we ingest the previous day flights (J-1) and for the 4, we ingest a new day in the future defined as J+90 days.

For the ingestion architecture we chose to implement a [Work Queue](https://www.rabbitmq.com/tutorials/tutorial-two-python) using Python and RabbitMQ.
- A producer will generate daily and for each endpoint the new URLs to query and send them to a particular queue.
- There is a queue for each one of the endpoints and the information is persisted on disk.
- A consumer is continuously listening on the other side of the queue, and will grab a new endpoint's URL, query de information on the Internet and store it into the database in raw format, in the l1 layer

This micro-services architecture has the following advantages from a monolitic one:
- Geneartion of endpoint urls and the consumtion of their data is asyncrhonous. Failures of endpoint querying are isolated of the endpoint generation.
- Increases tracability of which endpoints were already queryied, and failures goes back to the queue.
- Allows to simplify the overall code logic of the ingestion, in particular in how to deal with exceptions.
- 

Where a producer will generate the new enpoints URL each day and send them to a queue. On the other side of the queue, there is a consumer, lisAnd the consumer will be listening to the queue for new endpoints to query

A Producer sends the new endpoints informations of the day to a queue, which sources them to a consumer, responible for querying the endpoint and inserting the data to the data base. This architecture allow us to decouple the generation of the enpoints URL (producer) and the extraction step (consumer), this way a fail in the extraction of the endpoints data does not interrumps the overall process for the daily update. This increases the resilience of the pipeline and decreases the code overhead needed for the scripts, because they don’t need the logic to deal with extraction errors, they just can fail safe, and the incomplete extracted enpoint will return to the queue, and will be retried in the next turn.

On the other hand, for the source 1 and 5 we did a one time extraction and ingestion worflow.
For 1, the reference data is extracted usind a bash script, loaded to a stagging area in the local filesystem and ingested in the data base L1, in JSON format
For the 5, selenium is used to scrap all the information relative to aircraft events in the web, the data is rearranged in a tabular format in the script and ingested in L1.

### Storage

The storage component is a data wharehouse composed by three Postgresql Schemas. L1, L2 and L3.
In L1 the data lands in the original format, raw. For example, JSON for the most part and tabular for the source 5 only. It is a pseudo stagging zone, used primarily for keeping the maximum amount of the original data without tranformations and filters.
Then, there are two types of automated pipelines that tranform and load the data to the second layer L2, where the data is higly normalized:
One based on python and orchestrated with airflow, to combine and normalize the data comming from sources 2 and 3.
Second, one based on SQL triggers deploied directly in the server to also normalize the data comming from the source 4. (no need of external orchestration)
Advantages of normalization the data in this step are:
Eliminates data duplication (eliminates redundancy)
Improves data quality, because foreing key relationship must be respected

Finally the L3, contains wide tables, aggregated and ready for the consumtion. This layer can be called the semantinc layer, because it contains the bussines logic developped with the field experts and applied to responde to the use cases.



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
- Update the DB for Metabase with the one in the repo
```shell
# Stop Metabase container
# Overwrite its DB file
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

## Services

![image](https://github.com/user-attachments/assets/bef7c63c-ce09-418f-be11-dfa081d6a92e)
