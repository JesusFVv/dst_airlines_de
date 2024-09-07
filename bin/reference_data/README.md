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
# TODO : creer un lien symbolique vers common pour que "common" soit accessible depuis "reference_data"
python3 ../common/runSqlScript.py ingestRefData_01_referenceDataRaw.sql /home/ubuntu/dst_airlines_de/bin/customer_flight_info/database.ini
python3 ./ingestRefData_02_ingestReferenceDataRaw.py /home/ubuntu/dst_airlines_de/bin/customer_flight_info/database.ini /home/ubuntu/dst_airlines_de/data/referenceData
python3 ../common/runSqlScript.py ingestRefData_03_referenceDataCooked.sql /home/ubuntu/dst_airlines_de/bin/customer_flight_info/database.ini
```

### Ingestion version docker

```shell
cd /home/ubuntu/dst_airlines_de/bin/reference_data/raw_loading/
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
 public | refdata_airports_raw  | table | dst_designer | permanent   | heap          | 2664 kB |
 public | refdata_cities_raw    | table | dst_designer | permanent   | heap          | 1472 kB |
 public | refdata_countries_raw | table | dst_designer | permanent   | heap          | 64 kB   |
 public | test_table            | table | dst_designer | permanent   | heap          | 0 bytes |
(6 rows)
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

#### aicraft Cooked

```sql
SELECT 
    count(*)
	-- aircraftCode, AirlineEquipCode
FROM (
    SELECT DISTINCT json_data->>'AircraftCode' AS aircraftCode, json_data->>'AirlineEquipCode' AS AirlineEquipCode
    FROM (
        SELECT jsonb_array_elements(data->'AircraftResource'->'AircraftSummaries'->'AircraftSummary') AS json_data
        FROM refdata_aircraft_raw
        WHERE jsonb_typeof(data->'AircraftResource'->'AircraftSummaries'->'AircraftSummary') = 'array'

        UNION ALL

        SELECT jsonb_array_elements(data->'AircraftResource'->'AircraftSummaries'->'AircraftSummary') AS json_data
        FROM refdata_aircraft_raw
        WHERE jsonb_typeof(data->'AircraftResource'->'AircraftSummaries'->'AircraftSummary') = 'object'
    ) AS airport_data
) AS aircraft_cooked
WHERE aircraftCode IS NOT NULL
-- LIMIT 10
;
```

### Airports

#### count

```sql
SELECT 
    COUNT(json_data->>'AirportCode') AS airport_count,
    json_data->'Names'->'Name'->'@LanguageCode' AS lang
FROM (
    SELECT jsonb_array_elements(data->'AirportResource'->'Airports'->'Airport') AS json_data
    FROM refdata_airports_raw
    WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'array'

    UNION ALL

    SELECT data->'AirportResource'->'Airports'->'Airport' AS json_data
    FROM refdata_airports_raw
    WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'object'
) AS airport_data
GROUP BY json_data->'Names'->'Name'->'@LanguageCode';
```

 - Si on veut ignorer les doublons :

```sql
SELECT 
    COUNT(*) AS airport_count,
    lang
FROM (
    SELECT DISTINCT json_data->>'AirportCode' AS airport_code, json_data->'Names'->'Name'->'@LanguageCode' AS lang
    FROM (
        SELECT jsonb_array_elements(data->'AirportResource'->'Airports'->'Airport') AS json_data
        FROM refdata_airports_raw
        WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'array'

        UNION ALL

        SELECT data->'AirportResource'->'Airports'->'Airport' AS json_data
        FROM refdata_airports_raw
        WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'object'
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
    SELECT jsonb_array_elements(data->'AirportResource'->'Airports'->'Airport') AS json_data
    FROM refdata_airports_raw
    WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'array'

    UNION ALL

    SELECT data->'AirportResource'->'Airports'->'Airport' AS json_data
    FROM refdata_airports_raw
    WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'object'
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
        SELECT jsonb_array_elements(data->'AirlineResource'->'Airlines'->'Airline') AS json_data
        FROM refdata_airlines_raw
        WHERE jsonb_typeof(data->'AirlineResource'->'Airlines'->'Airline') = 'array'

        UNION ALL

        SELECT data->'AirlineResource'->'Airlines'->'Airline' AS json_data
        FROM refdata_airlines_raw
        WHERE jsonb_typeof(data->'AirlineResource'->'Airlines'->'Airline') = 'object'
    ) AS Airline_data
) AS airlines_codes_langs
GROUP BY lang;
```

```sql
SELECT json_data->'AirlineID' AS AirlineID, json_data->'Names'->'Name'->'@LanguageCode' AS lang
FROM (
	SELECT jsonb_array_elements(data->'AirlineResource'->'Airlines'->'Airline') AS json_data
	FROM refdata_airlines_raw
	WHERE jsonb_typeof(data->'AirlineResource'->'Airlines'->'Airline') = 'array'

	UNION ALL

	SELECT data->'AirlineResource'->'Airlines'->'Airline' AS json_data
	FROM refdata_airlines_raw
	WHERE jsonb_typeof(data->'AirlineResource'->'Airlines'->'Airline') = 'object'
) AS Airline_data
WHERE json_data->'Names'->'Name'->'@LanguageCode' IS NULL;
```

#### airlines Cooked

```sql
SELECT 
    count(*)
	-- AirlineID, AirlineID_ICAO
FROM (
    SELECT DISTINCT json_data->>'AirlineID' AS AirlineID, json_data->>'AirlineID_ICAO' AS AirlineID_ICAO
    FROM (
        SELECT jsonb_array_elements(data->'AirlineResource'->'Airlines'->'Airline') AS json_data
        FROM refdata_airlines_raw
        WHERE jsonb_typeof(data->'AirlineResource'->'Airlines'->'Airline') = 'array'

        UNION ALL

        SELECT jsonb_array_elements(data->'AirlineResource'->'Airlines'->'Airline') AS json_data
        FROM refdata_airlines_raw
        WHERE jsonb_typeof(data->'AirlineResource'->'Airlines'->'Airline') = 'object'
    ) AS airline_data
) AS airline_cooked
WHERE AirlineID IS NOT NULL
-- LIMIT 10
;
```

#### countries Cooked

```sql
SELECT 
    count(*)
	-- CountryCode
FROM (
    SELECT DISTINCT json_data->>'CountryCode' AS CountryCode
    FROM (
        SELECT jsonb_array_elements(data->'CountryResource'->'Countries'->'Country') AS json_data
        FROM refdata_countries_raw
        WHERE jsonb_typeof(data->'CountryResource'->'Countries'->'Country') = 'array'

        UNION ALL

        SELECT jsonb_array_elements(data->'CountryResource'->'Countries'->'Country') AS json_data
        FROM refdata_countries_raw
        WHERE jsonb_typeof(data->'CountryResource'->'Countries'->'Country') = 'object'
    ) AS countrie_data
) AS countrie_cooked
WHERE CountryCode IS NOT NULL
-- LIMIT 10
;
```

### Cooked Languages

```sql
SELECT * FROM refdata_languages_coo;
```

### Cooked count all

```sql
SELECT * FROM 
(
	SELECT 'refdata_languages_coo' as table, count(*) AS cnt FROM refdata_languages_coo
	UNION
	SELECT 'refdata_countries_coo' as table, count(*) AS cnt  FROM refdata_countries_coo
	UNION
	SELECT 'refdata_cities_coo' as table, count(*) AS cnt  FROM refdata_cities_coo
	UNION
	SELECT 'refdata_airports_coo' as table, count(*) AS cnt  FROM refdata_airports_coo
	UNION
	SELECT 'refdata_airlines_coo' as table, count(*) AS cnt  FROM refdata_airlines_coo
	UNION
	SELECT 'refdata_airport_names_coo' as table, count(*) AS cnt  FROM refdata_airport_names_coo
	UNION
	SELECT 'refdata_city_names_coo' as table, count(*) AS cnt  FROM refdata_city_names_coo
	UNION
	SELECT 'refdata_country_names_coo' as table, count(*) AS cnt  FROM refdata_country_names_coo
	UNION
	SELECT 'refdata_airline_names_coo' as table, count(*) AS cnt  FROM refdata_airline_names_coo
	UNION
	SELECT 'refdata_aircraft_names_coo' as table, count(*) AS cnt  FROM refdata_aircraft_names_coo
	UNION
	SELECT 'refdata_aircraft_coo' as table, count(*) AS cnt  FROM refdata_aircraft_coo
) ORDER BY cnt DESC;

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
