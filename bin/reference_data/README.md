# Ingestion Reference Data

## Lancement docker postgresql

 - Remarque cf. [partie initialisation docker](#initialisation-docker) si nécessaire

```shell
cd /home/ubuntu/dst_airlines_de/src/project_deployment_postgres
docker-compose up -d
```

## Ingestion

```shell
cd /home/ubuntu/dst_airlines_de
```

### Prérequis

```shell
chmod 755 ./bin/common/runSqlScript.py
chmod 755 ./bin/common/utils.py
chmod 755 ./bin/reference_data/ingestRefData_00_initConfigure.sh
chmod 755 ./bin/reference_data/ingestRefData_02_ingestReferenceDataRaw.py
# init
sudo ./bin/reference_data/ingestRefData_00_initConfigure.sh
```

### Ingestion

```shell
cd /home/ubuntu/dst_airlines_de/bin/reference_data/
chmod 755 ingestRefData_raw.sh
./ingestRefData_raw.sh -l
# python3 ../common/runSqlScript.py ingestRefData_01_referenceDataRaw.sql /home/ubuntu/dst_airlines_de/bin/customer_flight_info/database.ini
# python3 ./ingestRefData_02_ingestReferenceDataRaw.py /home/ubuntu/dst_airlines_de/bin/customer_flight_info/database.ini /home/ubuntu/dst_airlines_de/data/referenceData
# python3 ../common/runSqlScript.py ingestRefData_03_referenceDataCooked.sql /home/ubuntu/dst_airlines_de/bin/customer_flight_info/database.ini
```

### Ingestion version docker

```shell
cd /home/ubuntu/dst_airlines_de/bin/reference_data/full_ingest/
chmod 755 printLogDocker.sh run_docker.sh
./run_docker.sh
```

### Nettoyage

```shell
cd /home/ubuntu/dst_airlines_de/data/referenceData
rm -r out_AircraftRaw out_AirlinesRaw outEN_AirportsRaw outEN_CitiesRaw outEN_CountriesRaw outFR_AirportsRaw outFR_CitiesRaw outFR_CountriesRaw
```

## Verifications SQL

### Docker

```shell
cd /home/ubuntu/dst_airlines_de/src/project_deployment_postgres
docker exec -it postgres bash
```

### Export de tables

```shell
pg_dump -U dst_designer -t l2.refdata_languages dst_airlines_db > /tmp/l2.refdata_languages.sql
pg_dump -U dst_designer -t l2.refdata_countries dst_airlines_db > /tmp/l2.refdata_countries.sql
pg_dump -U dst_designer -t l2.refdata_cities dst_airlines_db > /tmp/l2.refdata_cities.sql
pg_dump -U dst_designer -t l2.refdata_airports dst_airlines_db > /tmp/l2.refdata_airports.sql
pg_dump -U dst_designer -t l2.refdata_airlines dst_airlines_db > /tmp/l2.refdata_airlines.sql
pg_dump -U dst_designer -t l2.refdata_aircraft dst_airlines_db > /tmp/l2.refdata_aircraft.sql
```

### Rappatriement des fichiers en local

```shell
cd /home/ubuntu/dst_airlines_de/data/referenceData
docker cp postgres:/tmp/l2.refdata_languages.sql /home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_languages.sql
docker cp postgres:/tmp/l2.refdata_countries.sql /home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_countries.sql
docker cp postgres:/tmp/l2.refdata_cities.sql /home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_cities.sql
docker cp postgres:/tmp/l2.refdata_airports.sql /home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_airports.sql
docker cp postgres:/tmp/l2.refdata_airlines.sql /home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_airlines.sql
docker cp postgres:/tmp/l2.refdata_aircraft.sql /home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_aircraft.sql

```

## Récupération sous WSL Ubuntu

```shell
scp -i "~/cle/data_enginering_machine.pem" ubuntu@3.249.2.75:/home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_languages.sql .
scp -i "~/cle/data_enginering_machine.pem" ubuntu@3.249.2.75:/home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_countries.sql .
scp -i "~/cle/data_enginering_machine.pem" ubuntu@3.249.2.75:/home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_cities.sql .
scp -i "~/cle/data_enginering_machine.pem" ubuntu@3.249.2.75:/home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_airports.sql .
scp -i "~/cle/data_enginering_machine.pem" ubuntu@3.249.2.75:/home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_airlines.sql .
scp -i "~/cle/data_enginering_machine.pem" ubuntu@3.249.2.75:/home/ubuntu/dst_airlines_de/data/referenceData/l2.refdata_aircraft.sql .

```


### Connexion à la base

```shell
psql -U dst_designer dst_airlines_db
```

### show tables

```sql
\dt+
```

```sql
 Schema |         Name          | Type  |    Owner     | Persistence | Access method |  Size   | Description
--------+-----------------------+-------+--------------+-------------+---------------+---------+-------------
 public | l1.refdata_aircraft  | table | dst_designer | permanent   | heap          | 64 kB   |
 public | l1.refdata_airlines  | table | dst_designer | permanent   | heap          | 96 kB   |
 public | l1.refdata_airports  | table | dst_designer | permanent   | heap          | 2664 kB |
 public | l1.refdata_cities    | table | dst_designer | permanent   | heap          | 1472 kB |
 public | l1.refdata_countries | table | dst_designer | permanent   | heap          | 64 kB   |
 public | test_table            | table | dst_designer | permanent   | heap          | 0 bytes |
(6 rows)
```

### Aircraft

#### count

```sql
SELECT COUNT(*) FROM l1.refdata_aircraft;
```

```sql
 count
-------
   382
(1 row)
```

#### name

```sql
SELECT data->'Names'->'Name'->>'$' AS aircraft_name
FROM l1.refdata_aircraft LIMIT 5;
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
SELECT (data->>'AircraftCode') AS aircraft_code,
       (data->'Names'->'Name'->>'$') AS aircraft_name
FROM l1.refdata_aircraft LIMIT 10;
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

#### aicraft Cooked

```sql
SELECT 
    count(*)
	-- aircraftCode, AirlineEquipCode
FROM (
    SELECT DISTINCT json_data->>'AircraftCode' AS aircraftCode, json_data->>'AirlineEquipCode' AS AirlineEquipCode
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_aircraft
    ) AS airport_data
) AS aircraft_cooked
WHERE aircraftCode IS NOT NULL
-- LIMIT 10
;
```

```log
 count
-------
   381
(1 row)
```

### Airports

#### count

```sql
SELECT 
    COUNT(json_data->>'AirportCode') AS airport_count,
    json_data->'Names'->'Name'->'@LanguageCode' AS lang
FROM (
    SELECT data AS json_data
    FROM l1.refdata_airports
) AS airport_data
GROUP BY json_data->'Names'->'Name'->'@LanguageCode';
```

```log
 airport_count | lang
---------------+------
             6 |
         15426 | "EN"
          8154 | "FR"
(3 rows)
```

 - Si on veut ignorer les doublons :

```sql
SELECT 
    COUNT(*) AS airport_count,
    lang
FROM (
    SELECT DISTINCT json_data->>'AirportCode' AS airport_code, json_data->'Names'->'Name'->'@LanguageCode' AS lang
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_airports
    ) AS airport_data
) AS airport_codes_langs
GROUP BY lang;
```

```sql
 airport_count | lang
---------------+------
             3 |
         11782 | "EN"
          8142 | "FR"
(3 rows)
```

#### Liste

```sql
SELECT 
    DISTINCT ON (json_data->>'AirportCode', json_data->'Names'->'Name'->'@LanguageCode')
    json_data->>'AirportCode' AS airport_code, 
	json_data->'Position'->'Coordinate'->'Latitude' AS Latitude, 
	json_data->'Position'->'Coordinate'->'Longitude' AS Longitude, 
	json_data->'CountryCode' AS country_code, 
	json_data->'Names'->'Name'->'@LanguageCode' AS lang, 
	json_data->'Names'->'Name'->'$' AS label
FROM (
    SELECT data AS json_data
    FROM l1.refdata_airports
) AS airport_data 
-- WHERE json_data->'Names'->'Name'->'$' IS NULL
ORDER BY json_data->>'AirportCode', json_data->'Names'->'Name'->'@LanguageCode', json_data->'Names'->'Name'->'$'
LIMIT 10 ;
```


```sql
 airport_code | latitude | longitude | country_code | lang |          label
--------------+----------+-----------+--------------+------+--------------------------
 AAA          | -17.3525 | -145.51   | "PF"         | "EN" | "Anaa"
 AAA          | -17.3525 | -145.51   | "PF"         | "FR" | "Anaa"
 AAB          | -26.6911 | 141.0472  | "AU"         | "EN" | "Arrabury Airport"
 AAC          | 31.0733  | 33.8358   | "EG"         | "EN" | "El Arish International"
 AAC          | 31.0733  | 33.8358   | "EG"         | "FR" | "Al Arish"
 AAD          | 6.0961   | 46.6375   | "SO"         | "EN" | "Adado Airport"
 AAE          | 36.8222  | 7.8092    | "DZ"         | "EN" | "Annaba Rabah Bitat"
 AAE          | 36.8222  | 7.8092    | "DZ"         | "FR" | "Annaba"
 AAF          | 29.7333  | -85.0333  | "US"         | "EN" | "Apalachicola"
 AAF          | 29.7333  | -85.0333  | "US"         | "FR" | "Apalachicola"
(10 rows)
```

#### Count airlines

```sql
SELECT 
    COUNT(*) AS airline_count,
    lang
FROM (
    SELECT json_data->'AirlineID' AS AirlineID, json_data->'Names'->'Name'->'@LanguageCode' AS lang
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_airlines
    ) AS Airline_data
) AS airlines_codes_langs
GROUP BY lang;
```

```log
 airline_count | lang
---------------+------
             1 |
          1131 | "EN"
(2 rows)
```

```sql
SELECT json_data->'AirlineID' AS AirlineID, json_data->'Names'->'Name'->'@LanguageCode' AS lang
FROM (
	SELECT data AS json_data
	FROM l1.refdata_airlines
) AS Airline_data
WHERE json_data->'Names'->'Name'->'@LanguageCode' IS NULL;
```

```log
 airlineid | lang
-----------+------
 "4Y"      |
(1 row)
```

#### airlines Cooked

```sql
SELECT 
    count(*)
	-- AirlineID, AirlineID_ICAO
FROM (
    SELECT DISTINCT json_data->>'AirlineID' AS AirlineID, json_data->>'AirlineID_ICAO' AS AirlineID_ICAO
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_airlines
    ) AS airline_data
) AS airline_cooked
WHERE AirlineID IS NOT NULL
-- LIMIT 10
;
```

```log
 count
-------
  1131
(1 row)
```

```sql
SELECT * FROM l3.view_airlines LIMIT 5;
```

```log
 airlineid | AirlineICAO | AirlineNameFR |    AirlineNameEN
-----------+-------------+---------------+----------------------
 0A        | GNT         |               | Amber Air
 0B        | BMS         |               | Blue Air
 0D        | DWT         |               | Darwin Airline Sa
 0J        | PJZ         |               | Premium Jet Ag
 0K        | KRT         |               | Aircompany Kokshetau
(5 rows)
```

#### cities Cooked

```sql
SELECT * FROM l3.view_cities LIMIT 5;
```

```log
 CityCode | CityNameFR | CityNameEN |  CountryNameFR   |  CountryNameEN
----------+------------+------------+------------------+------------------
 AAA      | Anaa       | Anaa       | French Polynesia | French Polynesia
 AAB      | Arrabury   | Arrabury   | Australie        | Australia
 AAC      | Al Arish   | El Arish   | Egypte           | Egypt
 AAD      |            | Adado      | Somalia          | Somalia
 AAE      | Annaba     | Annaba     | Algérie          | Algeria
(5 rows)
```

#### countries Cooked

```sql
SELECT 
    count(*)
	-- CountryCode
FROM (
    SELECT DISTINCT json_data->>'CountryCode' AS CountryCode
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_countries
    ) AS countrie_data
) AS countrie_cooked
WHERE CountryCode IS NOT NULL
-- LIMIT 10
;
```

```log
 count
-------
   238
(1 row)
```

```sql
SELECT * FROM l3.view_countries LIMIT 5;
```

```log
 CountryCode |   CountryNameFR    |            CountryNameEN
-------------+--------------------+--------------------------------------
 AD          | Andorra            | Andorra
 AE          | Emirat Arabes Unis | United Arab Emirates
 AF          | Afghanistan        | Afghanistan
 AG          |                    | Antigua And Barbuda, Leeward Islands
 AI          |                    | Anguilla, Leeward Islands
(5 rows)
```

#### aircraft Cooked

```sql
SELECT * FROM l3.view_aircrafts LIMIT 5;
```

```log
 AircraftCode | AircraftNameFR |        AircraftNameEN         | AircraftEquipCode
--------------+----------------+-------------------------------+-------------------
 100          |                | Fokker 100                    | F100
 141          |                | BAE Systems 146-100 Passenger | B461
 142          |                | BAE Systems 146-200 Passenger | B462
 143          |                | BAE Systems 146-300 Passenger | B463
 14X          |                | BAE Systems 146-100 Freighter | B461
(5 rows)
```

#### airport Cooked

```sql
SELECT * FROM l3.l3.view_airports_sample LIMIT 5;
```

```log
 AirportCode | AirportNameFR | AirportNameEN | CityNameFR | CityNameEN | CountryNameFR |      CountryNameEN       | AirportLatitude | AirportLongitude | AirportLocationType | AirportUTC_offset | AirportTimeZoneId
-------------+---------------+---------------+------------+------------+---------------+--------------------------+-----------------+------------------+---------------------+-------------------+-------------------
 ALG         | Alger         | Algiers       | Alger      | Algiers    | Algérie       | Algeria                  |         36.6942 |           3.2147 | Airport             |                 1 | Africa/Algiers
 AMS         | Amsterdam     | Amsterdam     | Amsterdam  | Amsterdam  | Pays-Bas      | Netherlands              |         52.3081 |           4.7642 | Airport             |                 1 | Europe/Amsterdam
 ARN         | Stockholm     | Stockholm     | Stockholm  | Stockholm  | Suède         | Sweden                   |         59.6519 |          17.9186 | Airport             |                 1 | Europe/Stockholm
 ATH         | Athènes       | Athens        | Athènes    | Athens     | Grèce         | Greece                   |         37.9364 |          23.9444 | Airport             |                 2 | Europe/Athens
 ATL         | Atlanta       | Atlanta       | Atlanta    | Atlanta    |               | United States Of America |         33.6367 |         -84.4281 | Airport             |                -5 | America/New_York
(5 rows)

```


### Cooked Languages

```sql
SELECT * FROM l2.refdata_languages;
```

### Cooked count all

```sql
SELECT * FROM 
(
	SELECT 'l2.refdata_languages' as table, count(*) AS cnt FROM l2.refdata_languages
	UNION
	SELECT 'l2.refdata_countries' as table, count(*) AS cnt  FROM l2.refdata_countries
	UNION
	SELECT 'l2.refdata_cities' as table, count(*) AS cnt  FROM l2.refdata_cities
	UNION
	SELECT 'l2.refdata_airports' as table, count(*) AS cnt  FROM l2.refdata_airports
	UNION
	SELECT 'l2.refdata_airlines' as table, count(*) AS cnt  FROM l2.refdata_airlines
	UNION
	SELECT 'l2.refdata_airport_names' as table, count(*) AS cnt  FROM l2.refdata_airport_names
	UNION
	SELECT 'l2.refdata_city_names' as table, count(*) AS cnt  FROM l2.refdata_city_names
	UNION
	SELECT 'l2.refdata_country_names' as table, count(*) AS cnt  FROM l2.refdata_country_names
	UNION
	SELECT 'l2.refdata_airline_names' as table, count(*) AS cnt  FROM l2.refdata_airline_names
	UNION
	SELECT 'l2.refdata_aircraft_names' as table, count(*) AS cnt  FROM l2.refdata_aircraft_names
	UNION
	SELECT 'l2.refdata_aircraft' as table, count(*) AS cnt  FROM l2.refdata_aircraft
) ORDER BY cnt DESC;

```

```log
           table            |  cnt
----------------------------+-------
 l2.refdata_airport_names  | 19924
 l2.refdata_city_names     | 18770
 l2.refdata_airports       | 11782
 l2.refdata_cities         | 10666
 l2.refdata_airlines       |  1127
 l2.refdata_airline_names  |  1127
 l2.refdata_country_names  |   424
 l2.refdata_aircraft       |   381
 l2.refdata_aircraft_names |   380
 l2.refdata_countries      |   238
 l2.refdata_languages      |     2
(11 rows)
```

# Initialisation docker

```shell
cd /home/ubuntu/dst_airlines_de/src/project_deployment_postgres
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
