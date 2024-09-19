-- ---------- --
-- RAW TABLES --
-- ---------- --
-- DELETE ALL RAW TABLES IF THEY ALREADY EXIST
DROP TABLE IF EXISTS refdata_aircraft_raw;
DROP TABLE IF EXISTS refdata_airlines_raw;
DROP TABLE IF EXISTS refdata_airports_raw;
DROP TABLE IF EXISTS refdata_cities_raw;
DROP TABLE IF EXISTS refdata_countries_raw;

CREATE TABLE IF NOT EXISTS refdata_aircraft_raw (
    id SERIAL PRIMARY KEY,
    data JSONB
);

CREATE TABLE IF NOT EXISTS refdata_airlines_raw (
    id SERIAL PRIMARY KEY,
    data JSONB
);

CREATE TABLE IF NOT EXISTS refdata_airports_raw (
    id SERIAL PRIMARY KEY,
    data JSONB
);

CREATE TABLE IF NOT EXISTS refdata_cities_raw (
    id SERIAL PRIMARY KEY,
    data JSONB
);

CREATE TABLE IF NOT EXISTS refdata_countries_raw (
    id SERIAL PRIMARY KEY,
    data JSONB
);

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
    -- 'Off-Line Point' added (ex.: XNS)
	-- 'Harbour' added (ex.: HKC : HONG KONG)
	-- 'Miscellaneous' added (ex.: OIL : Libya, Ras Lanuf Oil)
    locationType VARCHAR(20) CHECK (locationType IN ('Airport', 'RailwayStation', 'BusStation', 'Off-Line Point', 'Harbour', 'Miscellaneous')),
    UTC_offset INT NOT NULL,
    TimeZoneId VARCHAR(50) NOT NULL
);

CREATE TABLE refdata_airlines_coo (
    -- Should beCHAR(2) but 41 airports are returned with 3 char by the API
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
    -- Should beCHAR(2) but 41 airports are returned with 3 char by the API
    Airline CHAR(3) NOT NULL REFERENCES refdata_airlines_coo(AirlineID),
    Lang CHAR(2) NOT NULL REFERENCES refdata_languages_coo(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (Airline, Lang)
);

CREATE TABLE refdata_aircraft_names_coo (
    Aircraft CHAR(3) NOT NULL REFERENCES refdata_aircraft_coo(aircraftCode),
    Lang CHAR(2) NOT NULL REFERENCES refdata_languages_coo(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (Aircraft, Lang)
);
