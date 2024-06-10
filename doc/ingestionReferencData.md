# Ingestion Reference Data

## Lancement docker postgresql

 - Remarque cf. [partie initialisation docker](#initialisation-docker) si nécessaire

```shell
cd /home/ubuntu/projet/dst_airlines_de/src/project_deployment_postgres
docker-compose up -d
```

## Ingestion

```shell
cd /home/ubuntu/projet/dst_airlines_de
```

### Prérequis

```shell
chmod 755 ./bin/ingestRefData_00_initConfigure.sh
chmod 755 ./bin/ingestRefData_02_initReferenceDataRaw.py
chmod 755 ./bin/ingestRefData_03_ingestReferenceDataRaw.py
# init
sudo ./bin/ingestRefData_00_initConfigure.sh
```

### Ingestion

```shell
cd /home/ubuntu/projet/dst_airlines_de/data/referenceData
python3 ../../bin/ingestRefData_02_initReferenceDataRaw.py ingestRefData_01_referenceDataRaw.sql
python3 ../../bin/ingestRefData_03_ingestReferenceDataRaw.py
rm -r outAircraftRaw outAirlinesRaw outAirportsRaw outCitiesRaw outCountriesRaw
```

## Verifications SQL

### Docker

```shell
cd /home/ubuntu/projet/dst_airlines_de/src/project_deployment_postgres
docker exec -it postgres bash
psql -U dst_designer dst_airlines_db
```

### show tables

```sql
\dt+
```

```sql
 Schema |         Name          | Type  |    Owner     | Persistence | Access method |  Size   | Description
--------+-----------------------+-------+--------------+-------------+---------------+---------+-------------
 public | refdata_aircraft_raw  | table | dst_designer | permanent   | heap          | 64 kB   |
 public | refdata_airlines_raw  | table | dst_designer | permanent   | heap          | 96 kB   |
 public | refdata_airports_raw  | table | dst_designer | permanent   | heap          | 1352 kB |
 public | refdata_cities_raw    | table | dst_designer | permanent   | heap          | 768 kB  |
 public | refdata_countries_raw | table | dst_designer | permanent   | heap          | 32 kB   |
```

### Aircraft

#### count

```sql
SELECT COUNT(*)
FROM (
    SELECT DISTINCT (jsonb_array_elements(data->'AircraftResource'->'AircraftSummaries'->'AircraftSummary')->'AircraftCode') AS aircraft_code
    FROM refdata_aircraft_raw
) AS subquery;
```

```sql
 count
-------
   381
(1 row)
```

#### name

```sql
SELECT jsonb_array_elements(data->'AircraftResource'->'AircraftSummaries'->'AircraftSummary')->'Names'->'Name'->>'$' AS aircraft_name
FROM refdata_aircraft_raw LIMIT 5;
```

```sql
         aircraft_name
-------------------------------
 Fokker 100
 BAE Systems 146-100 Passenger
 BAE Systems 146-200 Passenger
 BAE Systems 146-300 Passenger
 BAE Systems 146-100 Freighter
(5 rows)
```

#### ID name

```sql
SELECT (aircraft->>'AircraftCode') AS aircraft_code,
       (aircraft->'Names'->'Name'->>'$') AS aircraft_name
FROM (
    SELECT jsonb_array_elements(data->'AircraftResource'->'AircraftSummaries'->'AircraftSummary') AS aircraft
    FROM refdata_aircraft_raw
) AS subquery LIMIT 10;
```

```sql
 aircraft_code |         aircraft_name
---------------+-------------------------------
 100           | Fokker 100
 141           | BAE Systems 146-100 Passenger
 142           | BAE Systems 146-200 Passenger
 143           | BAE Systems 146-300 Passenger
 14X           | BAE Systems 146-100 Freighter
 14Y           | BAE Systems 146-200 Freighter
 14Z           | BAE Systems 146-300 Freighter
 221           | Airbus A220-100
 223           | Airbus A220-300
 290           | E190-E2
(10 rows)
```

### Airports

#### count

```sql
SELECT count(json_data->>'AirportCode') AS airport_count
FROM (
    SELECT jsonb_array_elements(data->'AirportResource'->'Airports'->'Airport') AS json_data
    FROM refdata_airports_raw
    WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'array'

    UNION ALL

    SELECT data->'AirportResource'->'Airports'->'Airport' AS json_data
    FROM refdata_airports_raw
    WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'object'
) AS airport_data;
```

```sql
 airport_count
---------------
         11791
(1 row)
```

#### Liste

```sql
SELECT json_data->>'AirportCode' AS airport_code
FROM (
    SELECT jsonb_array_elements(data->'AirportResource'->'Airports'->'Airport') AS json_data
    FROM refdata_airports_raw
    WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'array'

    UNION ALL

    SELECT data->'AirportResource'->'Airports'->'Airport' AS json_data
    FROM refdata_airports_raw
    WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'object'
) AS airport_data ORDER BY airport_code LIMIT 10 ;
```

```sql
 airport_code
--------------
 AAA
 AAB
 AAC
 AAD
 AAE
 AAF
 AAG
 AAH
 AAI
 AAJ
(10 rows)
```


# Initialisation docker

```shell
cd /home/ubuntu/projet/dst_airlines_de/src/project_deployment_postgres
```

## Edition docker-compose

```shell
nano docker-compose.yml
```

 - Modifier ces deux lignes :
 
| Avant                | Après          |
|----------------------|----------------|
|`version: '3.9'`      |`version: '3.3'`|
|`name: custom_compose`|``              |

## Déploiement du docker

```shell
docker-compose up -d
# Ou eventuellement : docker-compose up --build
# Vérification :
docker ps
CONTAINER ID   IMAGE                        COMMAND                  CREATED          STATUS                          PORTS                    NAMES
41523b6a4990   dbeaver/cloudbeaver:latest   "./run-server.sh"        14 minutes ago   Restarting (1) 40 seconds ago                            dbeaver
19f410f9ff38   postgres:16.3-bullseye       "docker-entrypoint.s…"   14 minutes ago   Up 14 minutes                   0.0.0.0:6432->5432/tcp   postgres
```

## Première connexion

```shell
docker exec -it postgres bash
apt-get update
apt-get install nano
psql -U dst_designer dst_airlines_db
-- show tables
\dt+
```

## Configuration sécurité

```shell
nano /var/lib/postgresql/data/pg_hba.conf
```

 - Modifier ces deux lignes :
 
| Avant                                                                       | Après                                                                         |
|-----------------------------------------------------------------------------|-------------------------------------------------------------------------------|
|`local   all             all                                     trust`      |`local   all             all                                     scram-sha-256`|
|`host    all             all             127.0.0.1/32            trust`      |`host    all             all             127.0.0.1/32            scram-sha-256`|


 - Sauvegarder,
 - Sortir du container,
 - Rédémarrer le docker :

```shell
docker restart postgres
```

## destruction container

### Version simple

```shell
docker-compose down --volumes
```

### Version plus détaillées

```shell
# List all containers by id:
docker container ls -qa
# run this to each container:
docker container rm [id]
# And same with volumes:
docker volume ls
docker volume rm [VolumeName]
# And same with networks:
docker network ls
docker network rm [NetworkID]
```
