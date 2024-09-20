/* Initialise de DB with all the new tables and views created during the project
 This script is launched if not previous persistent volume exists
 */

CREATE TABLE IF NOT EXISTS public.test_table (
  id_user CHAR(36) NOT NULL,
  username VARCHAR(14) NOT NULL,
  date_joined DATE NULL,
  PRIMARY KEY (id_user));
  
-- -------------- --
-- REFERENCE DATA --
-- -------------- -- 

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
-- ----------- --
-- COOKED VIEW --
-- ----------- --
CREATE VIEW view_countries AS
SELECT 
    c.Code AS "CountryCode",
    cn_fr.Name AS "CountryNameFR",
    cn_en.Name AS "CountryNameEN"
FROM 
    refdata_countries_coo c
    LEFT JOIN refdata_country_names_coo cn_fr ON c.Code = cn_fr.Country AND cn_fr.Lang = 'FR'
    LEFT JOIN refdata_country_names_coo cn_en ON c.Code = cn_en.Country AND cn_en.Lang = 'EN';

CREATE VIEW view_cities AS
SELECT 
    ci.City AS "CityCode",
    ci_fr.Name AS "CityNameFR",
    ci_en.Name AS "CityNameEN",
    cn_fr.Name AS "CountryNameFR",
    cn_en.Name AS "CountryNameEN"
FROM 
    refdata_cities_coo ci
    LEFT JOIN refdata_city_names_coo ci_fr ON ci.City = ci_fr.City AND ci_fr.Lang = 'FR'
    LEFT JOIN refdata_city_names_coo ci_en ON ci.City = ci_en.City AND ci_en.Lang = 'EN'
    LEFT JOIN refdata_country_names_coo cn_fr ON ci.Country = cn_fr.Country AND cn_fr.Lang = 'FR'
    LEFT JOIN refdata_country_names_coo cn_en ON ci.Country = cn_en.Country AND cn_en.Lang = 'EN';

CREATE VIEW view_airports AS
SELECT 
    a.Airport AS "AirportCode",
    an_fr.Name AS "AirportNameFR",
    an_en.Name AS "AirportNameEN",
    ci_fr.Name AS "CityNameFR",
    ci_en.Name AS "CityNameEN",
    cn_fr.Name AS "CountryNameFR",
    cn_en.Name AS "CountryNameEN",
    a.Latitude AS "AirportLatitude",
    a.Longitude AS "AirportLongitude",
    a.locationType AS "AirportLocationType",
    a.UTC_offset AS "AirportUTC_offset",
    a.TimeZoneId AS "AirportTimeZoneId"
FROM 
    refdata_airports_coo a
    LEFT JOIN refdata_airport_names_coo an_fr ON a.Airport = an_fr.Airport AND an_fr.Lang = 'FR'
    LEFT JOIN refdata_airport_names_coo an_en ON a.Airport = an_en.Airport AND an_en.Lang = 'EN'
    LEFT JOIN refdata_city_names_coo ci_fr ON a.City = ci_fr.City AND ci_fr.Lang = 'FR'
    LEFT JOIN refdata_city_names_coo ci_en ON a.City = ci_en.City AND ci_en.Lang = 'EN'
    LEFT JOIN refdata_country_names_coo cn_fr ON a.Country = cn_fr.Country AND cn_fr.Lang = 'FR'
    LEFT JOIN refdata_country_names_coo cn_en ON a.Country = cn_en.Country AND cn_en.Lang = 'EN';

CREATE VIEW view_airports_sample AS
SELECT 
    a.Airport AS "AirportCode",
    an_fr.Name AS "AirportNameFR",
    an_en.Name AS "AirportNameEN",
    ci_fr.Name AS "CityNameFR",
    ci_en.Name AS "CityNameEN",
    cn_fr.Name AS "CountryNameFR",
    cn_en.Name AS "CountryNameEN",
    a.Latitude AS "AirportLatitude",
    a.Longitude AS "AirportLongitude",
    a.locationType AS "AirportLocationType",
    a.UTC_offset AS "AirportUTC_offset",
    a.TimeZoneId AS "AirportTimeZoneId"
FROM 
    refdata_airports_coo a
    LEFT JOIN refdata_airport_names_coo an_fr ON a.Airport = an_fr.Airport AND an_fr.Lang = 'FR'
    LEFT JOIN refdata_airport_names_coo an_en ON a.Airport = an_en.Airport AND an_en.Lang = 'EN'
    LEFT JOIN refdata_city_names_coo ci_fr ON a.City = ci_fr.City AND ci_fr.Lang = 'FR'
    LEFT JOIN refdata_city_names_coo ci_en ON a.City = ci_en.City AND ci_en.Lang = 'EN'
    LEFT JOIN refdata_country_names_coo cn_fr ON a.Country = cn_fr.Country AND cn_fr.Lang = 'FR'
    LEFT JOIN refdata_country_names_coo cn_en ON a.Country = cn_en.Country AND cn_en.Lang = 'EN'
WHERE a.Airport IN  (
  'IATA','DMM','DXB','PVG','BKK','IST','HND','PEK','DEL','CAI',
  'CMN','CPT','LOS','ALG','NBO','SSH','MRU','ATL','DFW','DEN',
  'ORD','LAX','JFK','LAS','MIA','MCO','CLT','MEX','SEA','EWR',
  'SFO','BOG','GRU','FRA','MUC','BER','AMS','LHR','MAN','OSL',
  'ARN','MAD','LIS','FCO','ATH','WAW','VIE','ZRH','DUB','NCE',
  'CDG')
;

CREATE VIEW view_airlines AS
SELECT 
    al.AirlineID,
    al.AirlineID_ICAO AS "AirlineICAO",
    an_fr.Name AS "AirlineNameFR",
    an_en.Name AS "AirlineNameEN"
FROM 
    refdata_airlines_coo al
    LEFT JOIN refdata_airline_names_coo an_fr ON al.AirlineID = an_fr.Airline AND an_fr.Lang = 'FR'
    LEFT JOIN refdata_airline_names_coo an_en ON al.AirlineID = an_en.Airline AND an_en.Lang = 'EN';

CREATE VIEW view_aircrafts AS
SELECT 
    ac.aircraftCode AS "AircraftCode",
    an_fr.Name AS "AircraftNameFR",
    an_en.Name AS "AircraftNameEN",
    ac.AirlineEquipCode AS "AircraftEquipCode"
FROM 
    refdata_aircraft_coo ac
    LEFT JOIN refdata_aircraft_names_coo an_fr ON ac.aircraftCode = an_fr.Aircraft AND an_fr.Lang = 'FR'
    LEFT JOIN refdata_aircraft_names_coo an_en ON ac.aircraftCode = an_en.Aircraft AND an_en.Lang = 'EN';

-- -------------------- --
-- CUSTOMER FLIGHT INFO --
-- -------------------- --

-- ---------- --
-- RAW TABLES --
-- ---------- --

-- DELETE RAW TABLE IF IT ALREADY EXISTS
DROP TABLE IF EXISTS operations_customer_flight_info_raw;

CREATE TABLE IF NOT EXISTS operations_customer_flight_info_raw (
    id SERIAL PRIMARY KEY,
    data JSONB NOT NULL
);


-- ------------- --
-- COOKED TABLES --
-- ------------- --

-- DELETE COOKED TABLE IF IT ALREADY EXISTS
DROP TABLE IF EXISTS operations_customer_flight_info_coo;

-- CREATE ENUM TYPE FOR FLIGHT CODES
CREATE TYPE departure_flight_code AS ENUM ('FE',
                                           'NI',
                                           'OT',
                                           'DL',
                                           'DP',
                                           'NO');

CREATE TYPE arrival_flight_code AS ENUM ('FE',
                                         'OT',
                                         'DL',
                                         'LD',
                                         'NO');

CREATE TYPE overall_flight_code AS ENUM ('CD',
                                         'DP',
                                         'LD',
                                         'RT',
                                         'DV',
                                         'HD',
                                         'FE',
                                         'DL',
                                         'OT',
                                         'NI',
                                         'NA');


CREATE TABLE IF NOT EXISTS operations_customer_flight_info_coo (
    id SERIAL,
    -- departure_airport_code CHAR(3) NOT NULL REFERENCES refdata_airports_coo(airport) ON DELETE CASCADE,
    departure_airport_code CHAR(3) NOT NULL,
    departure_scheduled_datetime TIMESTAMP,
    departure_estimated_datetime TIMESTAMP,
    departure_actual_datetime TIMESTAMP,
    departure_terminal_name TEXT,
    departure_terminal_gate TEXT,
    departure_status_code departure_flight_code,
    departure_status_description TEXT,
    -- arrival_airport_code CHAR(3) NOT NULL REFERENCES refdata_airports_coo(airport) ON DELETE CASCADE,
    arrival_airport_code CHAR(3) NOT NULL,
    arrival_scheduled_datetime TIMESTAMP,
    arrival_estimated_datetime TIMESTAMP,
    arrival_actual_datetime TIMESTAMP,
    arrival_terminal_name TEXT,
    arrival_terminal_gate TEXT,
    arrival_status_code arrival_flight_code,
    arrival_status_description TEXT,
    -- operating_airline_id CHAR(3) NOT NULL REFERENCES refdata_airlines_coo(airlineid) ON DELETE CASCADE,
    operating_airline_id CHAR(3) NOT NULL,
    operating_flight_nb INTEGER,
    equipment_aircraft_code CHAR(3),
    overall_status_code overall_flight_code,
    overall_status_description TEXT,
    CONSTRAINT customer_flight_info_pk
       PRIMARY KEY(operating_airline_id, operating_flight_nb, departure_scheduled_datetime)
);
