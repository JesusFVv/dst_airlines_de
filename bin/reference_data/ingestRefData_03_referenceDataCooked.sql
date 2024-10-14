-- ------------- --
-- COOKED TABLES --
-- ------------- --
-- TRUNCATE COOKED TABLES
DELETE FROM l2.refdata_airport_names;
DELETE FROM l2.refdata_airports;
DELETE FROM l2.refdata_city_names;
DELETE FROM l2.refdata_cities;
DELETE FROM l2.refdata_country_names;
DELETE FROM l2.refdata_airline_names;
DELETE FROM l2.refdata_aircraft_names;
DELETE FROM l2.refdata_languages;
DELETE FROM l2.refdata_countries;
DELETE FROM l2.refdata_airlines;
DELETE FROM l2.refdata_aircraft;

-- -------------------------------- --
-- INSERT INTO l2.refdata_aircraft --
-- -------------------------------- --

INSERT INTO l2.refdata_aircraft (aircraftCode, AirlineEquipCode)
SELECT 
    aircraftCode, AirlineEquipCode
FROM (
    SELECT DISTINCT json_data->>'AircraftCode' AS aircraftCode, json_data->>'AirlineEquipCode' AS AirlineEquipCode
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_aircraft
    ) AS aircraft_data
) AS aircraft_cooked
WHERE aircraftCode IS NOT NULL
ON CONFLICT (aircraftCode) DO NOTHING;

-- -------------------------------- --
-- INSERT INTO l2.refdata_airlines --
-- -------------------------------- --

INSERT INTO l2.refdata_airlines (AirlineID, AirlineID_ICAO)
SELECT 
    AirlineID, AirlineID_ICAO
FROM (
    SELECT DISTINCT json_data->>'AirlineID' AS AirlineID, json_data->>'AirlineID_ICAO' AS AirlineID_ICAO
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_airlines
    ) AS airline_data
) AS airline_cooked
WHERE AirlineID IS NOT NULL
ON CONFLICT (AirlineID) DO NOTHING;

-- --------------------------------- --
-- INSERT INTO l2.refdata_languages --
-- --------------------------------- --

-- Languages from airports
INSERT INTO l2.refdata_languages (Code)
SELECT DISTINCT 
    (json_data->'Names'->'Name'->>'@LanguageCode') AS lang
FROM (
    SELECT data AS json_data
    FROM l1.refdata_airports
) AS airport_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (Code) DO NOTHING;


-- Languages from Airlines
INSERT INTO l2.refdata_languages (Code)
SELECT DISTINCT 
    (json_data->'Names'->'Name'->>'@LanguageCode') AS lang
FROM (
	SELECT data AS json_data
	FROM l1.refdata_airlines
) AS Airline_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (Code) DO NOTHING;

-- Languages from aircraft
INSERT INTO l2.refdata_languages (Code)
SELECT DISTINCT 
    (json_data->'Names'->'Name'->>'@LanguageCode') AS lang
FROM (
	SELECT data AS json_data
	FROM l1.refdata_aircraft
) AS Aircraft_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (Code) DO NOTHING;

-- Languages from cities
INSERT INTO l2.refdata_languages (Code)
SELECT DISTINCT 
    (json_data->'Names'->'Name'->>'@LanguageCode') AS lang
FROM (
	SELECT data AS json_data
	FROM l1.refdata_cities
) AS City_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (Code) DO NOTHING;

-- Languages from countries
INSERT INTO l2.refdata_languages (Code)
SELECT DISTINCT 
    (json_data->'Names'->'Name'->>'@LanguageCode') AS lang
FROM (
	SELECT data AS json_data
	FROM l1.refdata_countries
) AS Country_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (Code) DO NOTHING;

-- -------------------------------- --
-- INSERT INTO l2.refdata_countries --
-- -------------------------------- --

INSERT INTO l2.refdata_countries (Code)
SELECT 
    CountryCode
FROM (
    SELECT DISTINCT json_data->>'CountryCode' AS CountryCode
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_countries
    ) AS countrie_data
) AS country_cooked
WHERE CountryCode IS NOT NULL
ON CONFLICT (Code) DO NOTHING;

-- ------------------------------ --
-- INSERT INTO l2.refdata_cities --
-- ------------------------------ --

INSERT INTO l2.refdata_cities (City, Country)
SELECT 
    CityCode, CountryCode
FROM (
    SELECT DISTINCT json_data->>'CityCode' AS CityCode, json_data->>'CountryCode' AS CountryCode
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_cities
    ) AS city_data
) AS city_cooked
WHERE CityCode IS NOT NULL
ON CONFLICT (City) DO NOTHING;




-- -------------------------------- --
-- INSERT INTO l2.refdata_airports --
-- -------------------------------- --
INSERT INTO l2.refdata_Airports (Airport, City, Country, Latitude, Longitude, locationType, UTC_offset, TimeZoneId)
SELECT 
    AirportCode, CityCode, CountryCode, Latitude, Longitude, LocationType, utcOffsetInt, TimeZoneId
FROM (
    SELECT DISTINCT 
	    json_data->>'AirportCode' AS AirportCode, 
		json_data->>'CityCode' AS CityCode, 
		json_data->>'CountryCode' AS CountryCode,
        (json_data->'Position'->'Coordinate'->>'Latitude')::float AS Latitude,
        (json_data->'Position'->'Coordinate'->>'Longitude')::float AS Longitude, 
		json_data->>'LocationType' AS LocationType, 
		json_data->>'UtcOffset' AS UtcOffset,
        -- Convertir le résultat de la comparaison en un type numérique
        CASE 
            WHEN SUBSTR(json_data->>'UtcOffset', 1, 1) = '+' THEN 1
            WHEN SUBSTR(json_data->>'UtcOffset', 1, 1) = '-' THEN -1
            ELSE 0
        END * (
            (SUBSTR(json_data->>'UtcOffset', 2, 2)::int + SUBSTR(json_data->>'UtcOffset', 5, 2)::int / 60.0)
        ) AS utcOffsetInt,
		json_data->>'TimeZoneId' AS TimeZoneId
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_airports
    ) AS Airport_data
) AS Airport_cooked
WHERE AirportCode IS NOT NULL
 AND LocationType IN ('Airport', 'RailwayStation', 'BusStation', 'Off-Line Point', 'Harbour', 'Miscellaneous')
ON CONFLICT (Airport) DO NOTHING;

-- Correct locationType 'Rail Station' to 'RailwayStation' (899)
INSERT INTO l2.refdata_Airports (Airport, City, Country, Latitude, Longitude, locationType, UTC_offset, TimeZoneId)
SELECT 
    AirportCode, CityCode, CountryCode, Latitude, Longitude, 'RailwayStation', utcOffsetInt, TimeZoneId
FROM (
    SELECT DISTINCT 
	    json_data->>'AirportCode' AS AirportCode, 
		json_data->>'CityCode' AS CityCode, 
		json_data->>'CountryCode' AS CountryCode,
        (json_data->'Position'->'Coordinate'->>'Latitude')::float AS Latitude,
        (json_data->'Position'->'Coordinate'->>'Longitude')::float AS Longitude, 
		json_data->>'LocationType' AS LocationType, 
		json_data->>'UtcOffset' AS UtcOffset,
        -- Convertir le résultat de la comparaison en un type numérique
        CASE 
            WHEN SUBSTR(json_data->>'UtcOffset', 1, 1) = '+' THEN 1
            WHEN SUBSTR(json_data->>'UtcOffset', 1, 1) = '-' THEN -1
            ELSE 0
        END * (
            (SUBSTR(json_data->>'UtcOffset', 2, 2)::int + SUBSTR(json_data->>'UtcOffset', 5, 2)::int / 60.0)
        ) AS utcOffsetInt,
		json_data->>'TimeZoneId' AS TimeZoneId
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_airports
    ) AS Airport_data
) AS Airport_cooked
WHERE AirportCode IS NOT NULL
 AND LocationType = 'Rail Station'
ON CONFLICT (Airport) DO NOTHING;

-- Correct locationType 'Bus Station' to 'BusStation' (274)
INSERT INTO l2.refdata_Airports (Airport, City, Country, Latitude, Longitude, locationType, UTC_offset, TimeZoneId)
SELECT 
    AirportCode, CityCode, CountryCode, Latitude, Longitude, 'BusStation', utcOffsetInt, TimeZoneId
FROM (
    SELECT DISTINCT 
	    json_data->>'AirportCode' AS AirportCode, 
		json_data->>'CityCode' AS CityCode, 
		json_data->>'CountryCode' AS CountryCode,
        (json_data->'Position'->'Coordinate'->>'Latitude')::float AS Latitude,
        (json_data->'Position'->'Coordinate'->>'Longitude')::float AS Longitude, 
		json_data->>'LocationType' AS LocationType, 
		json_data->>'UtcOffset' AS UtcOffset,
        -- Convertir le résultat de la comparaison en un type numérique
        CASE 
            WHEN SUBSTR(json_data->>'UtcOffset', 1, 1) = '+' THEN 1
            WHEN SUBSTR(json_data->>'UtcOffset', 1, 1) = '-' THEN -1
            ELSE 0
        END * (
            (SUBSTR(json_data->>'UtcOffset', 2, 2)::int + SUBSTR(json_data->>'UtcOffset', 5, 2)::int / 60.0)
        ) AS utcOffsetInt,
		json_data->>'TimeZoneId' AS TimeZoneId
    FROM (
        SELECT data AS json_data
        FROM l1.refdata_airports
    ) AS Airport_data
) AS Airport_cooked
WHERE AirportCode IS NOT NULL
 AND LocationType = 'Bus Station'
ON CONFLICT (Airport) DO NOTHING;

-- ------------------------------------- --
-- INSERT INTO l2.refdata_country_names --
-- ------------------------------------- --

INSERT INTO l2.refdata_country_names (Country, Lang, Name)
SELECT DISTINCT 
    (json_data->>'CountryCode') AS Country,
	(json_data->'Names'->'Name'->>'@LanguageCode') AS Lang,
	(json_data->'Names'->'Name'->>'$') AS Name
FROM (
	SELECT data AS json_data
	FROM l1.refdata_countries
) AS Country_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (Country, Lang) DO NOTHING;

-- ---------------------------------- --
-- INSERT INTO l2.refdata_city_names --
-- ---------------------------------- --

INSERT INTO l2.refdata_city_names (City, Lang, Name)
SELECT DISTINCT 
    (json_data->>'CityCode') AS City,
	(json_data->'Names'->'Name'->>'@LanguageCode') AS Lang,
	(json_data->'Names'->'Name'->>'$') AS Name
FROM (
	SELECT data AS json_data
	FROM l1.refdata_cities
) AS City_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (City, Lang) DO NOTHING;

-- ------------------------------------- --
-- INSERT INTO l2.refdata_airport_names --
-- ------------------------------------- --

INSERT INTO l2.refdata_airport_names (Airport, Lang, Name)
SELECT DISTINCT 
    (json_data->>'AirportCode') AS Airport,
	(json_data->'Names'->'Name'->>'@LanguageCode') AS Lang,
	(json_data->'Names'->'Name'->>'$') AS Name
FROM (
	SELECT data AS json_data
	FROM l1.refdata_airports
) AS Airport_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (Airport, Lang) DO NOTHING;

-- ------------------------------------- --
-- INSERT INTO l2.refdata_airline_names --
-- ------------------------------------- --

INSERT INTO l2.refdata_airline_names (Airline, Lang, Name)
SELECT DISTINCT 
    (json_data->>'AirlineID') AS Airline,
	(json_data->'Names'->'Name'->>'@LanguageCode') AS Lang,
	(json_data->'Names'->'Name'->>'$') AS Name
FROM (
	SELECT data AS json_data
	FROM l1.refdata_airlines
) AS Airline_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (Airline, Lang) DO NOTHING;

-- -------------------------------------- --
-- INSERT INTO l2.refdata_aircraft_names --
-- -------------------------------------- --

INSERT INTO l2.refdata_aircraft_names (Aircraft, Lang, Name)
SELECT DISTINCT 
    (json_data->>'AircraftCode') AS Aircraft,
	(json_data->'Names'->'Name'->>'@LanguageCode') AS Lang,
	(json_data->'Names'->'Name'->>'$') AS Name
FROM (
	SELECT data AS json_data
	FROM l1.refdata_aircraft
) AS Aircraft_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (Aircraft, Lang) DO NOTHING;
