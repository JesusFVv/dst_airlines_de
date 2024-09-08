-- ------------- --
-- COOKED TABLES --
-- ------------- --
-- DELETE ALL COOKED TABLES IF THEY ALREADY EXIST
DROP TABLE IF EXISTS refdata_airport_names_coo;
DROP TABLE IF EXISTS refdata_airports_coo;
DROP TABLE IF EXISTS refdata_city_names_coo;
DROP TABLE IF EXISTS refdata_cities_coo;
DROP TABLE IF EXISTS refdata_country_names_coo;
DROP TABLE IF EXISTS refdata_airline_names_coo;
DROP TABLE IF EXISTS refdata_aircraft_names_coo;
DROP TABLE IF EXISTS refdata_languages_coo;
DROP TABLE IF EXISTS refdata_countries_coo;
DROP TABLE IF EXISTS refdata_airlines_coo;
DROP TABLE IF EXISTS refdata_aircraft_coo;

-- main tables
CREATE TABLE refdata_languages_coo (
    Code CHAR(2) PRIMARY KEY
);

CREATE TABLE refdata_countries_coo (
    Code CHAR(2) PRIMARY KEY
);

CREATE TABLE refdata_cities_coo (
    City CHAR(3) PRIMARY KEY,
    Country CHAR(2) NOT NULL REFERENCES refdata_countries_coo(Code)
);

CREATE TABLE refdata_airports_coo (
    Airport CHAR(3) PRIMARY KEY,
    City CHAR(3) NOT NULL REFERENCES refdata_cities_coo(City),
    Country CHAR(2) NOT NULL REFERENCES refdata_countries_coo(Code),
    Latitude DECIMAL NOT NULL,
    Longitude DECIMAL NOT NULL,
	-- 'Off-Line Point' added (XNS)
	-- 'Harbour' added (HKC : HONG KONG)
	-- 'Miscellaneous' added (OIL : Libya, Ras Lanuf Oil)
    locationType VARCHAR(20) CHECK (locationType IN ('Airport', 'RailwayStation', 'BusStation', 'Off-Line Point', 'Harbour', 'Miscellaneous')),
    UTC_offset INT NOT NULL,
    TimeZoneId VARCHAR(50) DEFAULT '?'  -- Should be NOT NULL but some airports with TimeZoneId null are returned by the API
);

CREATE TABLE refdata_airlines_coo (
    AirlineID CHAR(3) PRIMARY KEY,
    AirlineID_ICAO CHAR(3)
);

CREATE TABLE refdata_aircraft_coo (
    aircraftCode CHAR(3) PRIMARY KEY,
    AirlineEquipCode VARCHAR(10)
);

-- Relation tables
CREATE TABLE refdata_country_names_coo (
    Country CHAR(2) NOT NULL REFERENCES refdata_countries_coo(Code),
    Lang CHAR(2) NOT NULL REFERENCES refdata_languages_coo(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (Country, Lang)
);

CREATE TABLE refdata_city_names_coo (
    City CHAR(3) NOT NULL REFERENCES refdata_cities_coo(City),
    Lang CHAR(2) NOT NULL REFERENCES refdata_languages_coo(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (City, Lang)
);

CREATE TABLE refdata_airport_names_coo (
    Airport CHAR(3) NOT NULL REFERENCES refdata_airports_coo(Airport),
    Lang CHAR(2) NOT NULL REFERENCES refdata_languages_coo(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (Airport, Lang)
);

CREATE TABLE refdata_airline_names_coo (
    Airline CHAR(2) NOT NULL REFERENCES refdata_airlines_coo(AirlineID),
    Lang CHAR(2) NOT NULL REFERENCES refdata_languages_coo(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (Airline, Lang)
);

CREATE TABLE refdata_aircraft_names_coo (
    refdata_aircraft_coo CHAR(3) NOT NULL REFERENCES refdata_aircraft_coo(aircraftCode),
    Lang CHAR(2) NOT NULL REFERENCES refdata_languages_coo(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (refdata_aircraft_coo, Lang)
);

-- -------------------------------- --
-- INSERT INTO refdata_aircraft_coo --
-- -------------------------------- --

INSERT INTO refdata_aircraft_coo (aircraftCode, AirlineEquipCode)
SELECT 
    aircraftCode, AirlineEquipCode
FROM (
    SELECT DISTINCT json_data->>'AircraftCode' AS aircraftCode, json_data->>'AirlineEquipCode' AS AirlineEquipCode
    FROM (
        SELECT jsonb_array_elements(data->'AircraftResource'->'AircraftSummaries'->'AircraftSummary') AS json_data
        FROM refdata_aircraft_raw
        WHERE jsonb_typeof(data->'AircraftResource'->'AircraftSummaries'->'AircraftSummary') = 'array'

        UNION ALL

        SELECT data->'AircraftResource'->'AircraftSummaries'->'AircraftSummary' AS json_data
        FROM refdata_aircraft_raw
        WHERE jsonb_typeof(data->'AircraftResource'->'AircraftSummaries'->'AircraftSummary') = 'object'
    ) AS aircraft_data
) AS aircraft_cooked
WHERE aircraftCode IS NOT NULL
ON CONFLICT (aircraftCode) DO NOTHING;

-- -------------------------------- --
-- INSERT INTO refdata_airlines_coo --
-- -------------------------------- --

INSERT INTO refdata_airlines_coo (AirlineID, AirlineID_ICAO)
SELECT 
    AirlineID, AirlineID_ICAO
FROM (
    SELECT DISTINCT json_data->>'AirlineID' AS AirlineID, json_data->>'AirlineID_ICAO' AS AirlineID_ICAO
    FROM (
        SELECT jsonb_array_elements(data->'AirlineResource'->'Airlines'->'Airline') AS json_data
        FROM refdata_airlines_raw
        WHERE jsonb_typeof(data->'AirlineResource'->'Airlines'->'Airline') = 'array'

        UNION ALL

        SELECT data->'AirlineResource'->'Airlines'->'Airline' AS json_data
        FROM refdata_airlines_raw
        WHERE jsonb_typeof(data->'AirlineResource'->'Airlines'->'Airline') = 'object'
    ) AS airline_data
) AS airline_cooked
WHERE AirlineID IS NOT NULL
ON CONFLICT (AirlineID) DO NOTHING;

-- --------------------------------- --
-- INSERT INTO refdata_languages_coo --
-- --------------------------------- --

-- Languages from airports
INSERT INTO refdata_languages_coo (Code)
SELECT DISTINCT 
    (json_data->'Names'->'Name'->>'@LanguageCode') AS lang
FROM (
    SELECT jsonb_array_elements(data->'AirportResource'->'Airports'->'Airport') AS json_data
    FROM refdata_airports_raw
    WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'array'

    UNION ALL

    SELECT data->'AirportResource'->'Airports'->'Airport' AS json_data
    FROM refdata_airports_raw
    WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'object'
) AS airport_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (Code) DO NOTHING;


-- Languages from Airlines
INSERT INTO refdata_languages_coo (Code)
SELECT DISTINCT 
    (json_data->'Names'->'Name'->>'@LanguageCode') AS lang
FROM (
	SELECT jsonb_array_elements(data->'AirlineResource'->'Airlines'->'Airline') AS json_data
	FROM refdata_airlines_raw
	WHERE jsonb_typeof(data->'AirlineResource'->'Airlines'->'Airline') = 'array'

	UNION ALL

	SELECT data->'AirlineResource'->'Airlines'->'Airline' AS json_data
	FROM refdata_airlines_raw
	WHERE jsonb_typeof(data->'AirlineResource'->'Airlines'->'Airline') = 'object'
) AS Airline_data
WHERE json_data->'Names'->'Name'->>'@LanguageCode' IS NOT NULL
ON CONFLICT (Code) DO NOTHING;

-- TODO : from aircraft, cities, countries

-- -------------------------------- --
-- INSERT INTO refdata_countries_coo --
-- -------------------------------- --

INSERT INTO refdata_countries_coo (Code)
SELECT 
    CountryCode
FROM (
    SELECT DISTINCT json_data->>'CountryCode' AS CountryCode
    FROM (
        SELECT jsonb_array_elements(data->'CountryResource'->'Countries'->'Country') AS json_data
        FROM refdata_countries_raw
        WHERE jsonb_typeof(data->'CountryResource'->'Countries'->'Country') = 'array'

        UNION ALL

        SELECT data->'CountryResource'->'Countries'->'Country' AS json_data
        FROM refdata_countries_raw
        WHERE jsonb_typeof(data->'CountryResource'->'Countries'->'Country') = 'object'
    ) AS countrie_data
) AS country_cooked
WHERE CountryCode IS NOT NULL
ON CONFLICT (Code) DO NOTHING;

-- ------------------------------ --
-- INSERT INTO refdata_cities_coo --
-- ------------------------------ --

INSERT INTO refdata_cities_coo (City, Country)
SELECT 
    CityCode, CountryCode
FROM (
    SELECT DISTINCT json_data->>'CityCode' AS CityCode, json_data->>'CountryCode' AS CountryCode
    FROM (
        SELECT jsonb_array_elements(data->'CityResource'->'Cities'->'City') AS json_data
        FROM refdata_cities_raw
        WHERE jsonb_typeof(data->'CityResource'->'Cities'->'City') = 'array'

        UNION ALL

        SELECT data->'CityResource'->'Cities'->'City' AS json_data
        FROM refdata_cities_raw
        WHERE jsonb_typeof(data->'CityResource'->'Cities'->'City') = 'object'
    ) AS countrie_data
) AS city_cooked
WHERE CityCode IS NOT NULL
ON CONFLICT (City) DO NOTHING;


-- -------------------------------- --
-- INSERT INTO refdata_airports_coo --
-- -------------------------------- --
INSERT INTO refdata_Airports_coo (Airport, City, Country, Latitude, Longitude, locationType, UTC_offset, TimeZoneId)
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
        SELECT jsonb_array_elements(data->'AirportResource'->'Airports'->'Airport') AS json_data
        FROM refdata_Airports_raw
        WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'array'

        UNION ALL

        SELECT data->'AirportResource'->'Airports'->'Airport' AS json_data
        FROM refdata_Airports_raw
        WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'object'
    ) AS Airport_data
) AS Airport_cooked
WHERE AirportCode IS NOT NULL
 AND LocationType IN ('Airport', 'RailwayStation', 'BusStation', 'Off-Line Point', 'Harbour', 'Miscellaneous')
ON CONFLICT (Airport) DO NOTHING;

-- Correct locationType 'Rail Station' to 'RailwayStation' (899)
INSERT INTO refdata_Airports_coo (Airport, City, Country, Latitude, Longitude, locationType, UTC_offset, TimeZoneId)
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
        SELECT jsonb_array_elements(data->'AirportResource'->'Airports'->'Airport') AS json_data
        FROM refdata_Airports_raw
        WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'array'

        UNION ALL

        SELECT data->'AirportResource'->'Airports'->'Airport' AS json_data
        FROM refdata_Airports_raw
        WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'object'
    ) AS Airport_data
) AS Airport_cooked
WHERE AirportCode IS NOT NULL
 AND LocationType = 'Rail Station'
ON CONFLICT (Airport) DO NOTHING;

-- Correct locationType 'Bus Station' to 'BusStation' (274)
INSERT INTO refdata_Airports_coo (Airport, City, Country, Latitude, Longitude, locationType, UTC_offset, TimeZoneId)
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
        SELECT jsonb_array_elements(data->'AirportResource'->'Airports'->'Airport') AS json_data
        FROM refdata_Airports_raw
        WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'array'

        UNION ALL

        SELECT data->'AirportResource'->'Airports'->'Airport' AS json_data
        FROM refdata_Airports_raw
        WHERE jsonb_typeof(data->'AirportResource'->'Airports'->'Airport') = 'object'
    ) AS Airport_data
) AS Airport_cooked
WHERE AirportCode IS NOT NULL
 AND LocationType = 'Bus Station'
ON CONFLICT (Airport) DO NOTHING;
