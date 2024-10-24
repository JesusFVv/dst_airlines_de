# Customer flight information airport
The process to extract, transform and load data from customer flight information airport endpoints is composed of 3 stages:
1. Extract data
2. Load l1 data
3. Load l2 data (data transformation is performed in this stage)

All these stages have been containerized through Docker.\
In the Datascientest VM, the Docker version is 20.10.3.

## Extract data
The first stage consists in collecting data from [Lufthansa Open API](https://developer.lufthansa.com/docs) for two endpoints:
- [Customer flight information at departure airport](https://developer.lufthansa.com/docs/read/api_details/operations/Customer_Flight_Information_at_Departure_Airport)
- [Customer flight information at arrival airport](https://developer.lufthansa.com/docs/read/api_details/operations/Customer_Flight_Information_at_Arrival_Airport)

The first endpoint retrieves the status of all flights departing from a specific airport within a given time range.\
The second endpoint retrieves the status of all flights arriving at a specific airport within a given time range.

### How to extract data?
The scripts `build_docker_image.sh` and `run_docker_container.sh` are the core of this stage.
```sh
cd ~/dst_airlines_de  # Project root directory
./lib/customer_flight_info/extraction/build_docker_image.sh
```
As a summary, this first script includes a series of tasks:
1. Create a temporary folder to be used as Docker build context
2. Clean Docker container and image
3. Build [Docker image](#dockerfile-data-extraction)

```sh
cd ~/dst_airlines_de  # Project root directory
./lib/customer_flight_info/extraction/run_docker_container.sh
```
This second script runs the Docker container.\
:exclamation: A volume is bound through the `docker run` command to pass data collected on host machine

#### Dockerfile data extraction
The Dockerfile uses Python 3.11 as base image and runs a [Python script](#python-script-data-extraction).

#### Python script data extraction
The Python script `extract_customer_flight_info.py`  is in charge of collecting data. This is done through 6 steps:
1. Read a list of airport IATA codes to be used as an input parameter
2. Generate a list of datetimes (`YYYY-mm-ddTHH:MM`) to be used as an input parameter
3. Get API token
4. Request endpoints within time ranges of 4 hours
5. Save data in JSON format
6. Zip files

:warning: As of now, this pipeline is triggered manually. Therefore, the datetimes given as input in the Python script have to be updated in order to retrieve data for each day (line 242).

## Load l1 data
The second stage consists in loading data that have been extracted from [stage 1](#extract-data) in a l1 table. These data are slightly trimmed to only store useful information.

### How to load l1 data?
:warning: Before loading l1 data, the Postgres database has to be up and running.
```sh
cd ~/dst_airlines_de  # Project root directory
bash dst_services_compose_up.sh
```
Then the scripts `build_docker_image.sh` and `run_docker_container.sh` are the core of this stage.
```sh
cd ~/dst_airlines_de  # Project root directory
./lib/customer_flight_info/l1_loading/build_docker_image.sh
```
As a summary, this first script includes a series of tasks:
1. Create a temporary folder to be used as Docker build context
2. Clean Docker container and image
3. Build [Docker image](#dockerfile-l1-loading)

```sh
cd ~/dst_airlines_de  # Project root directory
./lib/customer_flight_info/l1_loading/run_docker_container.sh
```
This second script runs the Docker container.\
:exclamation: Two volumes are bound through the `docker run` command to get access to the data and database credentials files\
:exclamation: A network is given through the `docker run` to be able to connect to the containerized database

#### Dockerfile l1 loading
The Dockerfile uses Python3.11 as base image and runs a [Python script](#python-script-l1-loading).

#### Python script l1 loading
The Python script `load_customer_flight_info_raw.py` is in charge of inserting raw data into the postgres table named `operations_customer_flight_info_raw`. This is done through 3 steps:
1. Unzip data files
2. Read data from these files
3. Ingest data into the database table

## Load cooked data
The third and last stage consists in loading data that have been stored from [stage 2](#load-raw-data) in a "cooked" table with a proper flattened format.

### How to load cooked data?
:warning: Before loading cooked data, the Postgres database has to be up and running with the stage 2 already completed.
```sh
cd /home/ubuntu/dst_airlines_de/src/project_deployment_postgres
docker-compose up -d
```
Then the script `run_docker.sh` is the core of this stage.
```sh
cd /home/ubuntu/dst_airlines_de/bin/customer_flight_info/cooked_loading
./run_docker.sh
```
As a summary, it includes a series of tasks:
1. Create a temporary folder to serve as a build context for Docker
2. Clean Docker container and images
3. Build [Docker image](#dockerfile-cooked-loading)
4. Run Docker

:exclamation: A network is given through the `docker run` to be able to connect to the containerized database

#### Dockerfile cooked loading
The Dockerfile uses Python3.11 as base image and runs a [Python script](#python-script-cooked-loading).

#### Python script cooked loading
The Python script `load_customer_flight_info_cooked.py` is in charge of inserting cooked data into the postgres table named `operations_customer_flight_info_coo`. This is done through 3 steps:
1. Read data from database raw table
2. Transform data from JSON format to a convenient flattened format
3. Ingest data into the database table
