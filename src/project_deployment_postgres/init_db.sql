/* Initialise de DB with all the new tables and views created during the project
 This script is launched if not previous persistent volume exists
 */

/*
CREATE TABLE IF NOT EXISTS public.test_table (
  id_user CHAR(36) NOT NULL,
  username VARCHAR(14) NOT NULL,
  date_joined DATE NULL,
  PRIMARY KEY (id_user));
*/

-- ------- --
-- SCHEMAS --
-- ------- --
-- DELETE ALL SCHEMAS IF THEY ALREADY EXIST
DROP SCHEMA IF EXISTS l1;
DROP SCHEMA IF EXISTS l2;
DROP SCHEMA IF EXISTS l3;

CREATE SCHEMA l1;
CREATE SCHEMA l2;
CREATE SCHEMA l3;

-- -------------- --
-- REFERENCE DATA --
-- -------------- --

-- --------------- --
-- RAW TABLES (L1) --
-- --------------- --
-- DELETE ALL RAW TABLES IF THEY ALREADY EXIST
DROP TABLE IF EXISTS l1.refdata_aircraft;
DROP TABLE IF EXISTS l1.refdata_airlines;
DROP TABLE IF EXISTS l1.refdata_airports;
DROP TABLE IF EXISTS l1.refdata_cities;
DROP TABLE IF EXISTS l1.refdata_countries;

CREATE TABLE IF NOT EXISTS l1.refdata_aircraft (
    id SERIAL PRIMARY KEY,
    data JSONB
);

CREATE TABLE IF NOT EXISTS l1.refdata_airlines (
    id SERIAL PRIMARY KEY,
    data JSONB
);

CREATE TABLE IF NOT EXISTS l1.refdata_airports (
    id SERIAL PRIMARY KEY,
    data JSONB
);

CREATE TABLE IF NOT EXISTS l1.refdata_cities (
    id SERIAL PRIMARY KEY,
    data JSONB
);

CREATE TABLE IF NOT EXISTS l1.refdata_countries (
    id SERIAL PRIMARY KEY,
    data JSONB
);

-- ------------------ --
-- COOKED TABLES (L2) --
-- ------------------ --
-- DELETE ALL COOKED TABLES IF THEY ALREADY EXIST
DROP TABLE IF EXISTS l2.refdata_airport_names;
DROP TABLE IF EXISTS l2.refdata_airports;
DROP TABLE IF EXISTS l2.refdata_city_names;
DROP TABLE IF EXISTS l2.refdata_cities;
DROP TABLE IF EXISTS l2.refdata_country_names;
DROP TABLE IF EXISTS l2.refdata_airline_names;
DROP TABLE IF EXISTS l2.refdata_aircraft_names;
DROP TABLE IF EXISTS l2.refdata_languages;
DROP TABLE IF EXISTS l2.refdata_countries;
DROP TABLE IF EXISTS l2.refdata_airlines;
DROP TABLE IF EXISTS l2.refdata_aircraft;

-- main tables
CREATE TABLE l2.refdata_languages (
    Code CHAR(2) PRIMARY KEY
);

CREATE TABLE l2.refdata_countries (
    Code CHAR(2) PRIMARY KEY
);

CREATE TABLE l2.refdata_cities (
    City CHAR(3) PRIMARY KEY,
    Country CHAR(2) NOT NULL REFERENCES l2.refdata_countries(Code)
);

CREATE TABLE l2.refdata_airports (
    Airport CHAR(3) PRIMARY KEY,
    City CHAR(3) NOT NULL REFERENCES l2.refdata_cities(City),
    Country CHAR(2) NOT NULL REFERENCES l2.refdata_countries(Code),
    Latitude DECIMAL NOT NULL,
    Longitude DECIMAL NOT NULL,
	-- 'Off-Line Point' added (ex.: XNS)
	-- 'Harbour' added (ex.: HKC : HONG KONG)
	-- 'Miscellaneous' added (ex.: OIL : Libya, Ras Lanuf Oil)
    locationType VARCHAR(20) CHECK (locationType IN ('Airport', 'RailwayStation', 'BusStation', 'Off-Line Point', 'Harbour', 'Miscellaneous')),
    UTC_offset INT NOT NULL,
    TimeZoneId VARCHAR(50) DEFAULT '?'  -- Should be NOT NULL but some airports with TimeZoneId null are returned by the API
);

CREATE TABLE l2.refdata_airlines (
    -- Should beCHAR(2) but 41 airports are returned with 3 char by the API
    AirlineID CHAR(3) PRIMARY KEY,
    AirlineID_ICAO CHAR(3)
);

CREATE TABLE l2.refdata_aircraft (
    aircraftCode CHAR(3) PRIMARY KEY,
    AirlineEquipCode VARCHAR(10)
);

-- Relation tables
CREATE TABLE l2.refdata_country_names (
    Country CHAR(2) NOT NULL REFERENCES l2.refdata_countries(Code),
    Lang CHAR(2) NOT NULL REFERENCES l2.refdata_languages(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (Country, Lang)
);

CREATE TABLE l2.refdata_city_names (
    City CHAR(3) NOT NULL REFERENCES l2.refdata_cities(City),
    Lang CHAR(2) NOT NULL REFERENCES l2.refdata_languages(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (City, Lang)
);

CREATE TABLE l2.refdata_airport_names (
    Airport CHAR(3) NOT NULL REFERENCES l2.refdata_airports(Airport),
    Lang CHAR(2) NOT NULL REFERENCES l2.refdata_languages(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (Airport, Lang)
);

CREATE TABLE l2.refdata_airline_names (
    -- Should beCHAR(2) but 41 airports are returned with 3 char by the API
    Airline CHAR(3) NOT NULL REFERENCES l2.refdata_airlines(AirlineID),
    Lang CHAR(2) NOT NULL REFERENCES l2.refdata_languages(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (Airline, Lang)
);

CREATE TABLE l2.refdata_aircraft_names (
    Aircraft CHAR(3) NOT NULL REFERENCES l2.refdata_aircraft(aircraftCode),
    Lang CHAR(2) NOT NULL REFERENCES l2.refdata_languages(Code),
    Name VARCHAR(100) NOT NULL,
    PRIMARY KEY (Aircraft, Lang)
);

-- ----------------- --
-- COOKED VIEWS (L3) --
-- ----------------- --
-- DELETE ALL VIEWS IF THEY ALREADY EXIST
DROP VIEW IF EXISTS l3.view_countries;
DROP VIEW IF EXISTS l3.view_cities;
DROP VIEW IF EXISTS l3.view_airports;
DROP VIEW IF EXISTS l3.view_airports_sample;
DROP VIEW IF EXISTS l3.view_airlines;
DROP VIEW IF EXISTS l3.view_aircrafts;

CREATE VIEW l3.view_countries AS
SELECT
    c.Code AS "CountryCode",
    cn_fr.Name AS "CountryNameFR",
    cn_en.Name AS "CountryNameEN"
FROM
    l2.refdata_countries c
    LEFT JOIN l2.refdata_country_names cn_fr ON c.Code = cn_fr.Country AND cn_fr.Lang = 'FR'
    LEFT JOIN l2.refdata_country_names cn_en ON c.Code = cn_en.Country AND cn_en.Lang = 'EN';

CREATE VIEW l3.view_cities AS
SELECT
    ci.City AS "CityCode",
    ci_fr.Name AS "CityNameFR",
    ci_en.Name AS "CityNameEN",
    cn_fr.Name AS "CountryNameFR",
    cn_en.Name AS "CountryNameEN"
FROM
    l2.refdata_cities ci
    LEFT JOIN l2.refdata_city_names ci_fr ON ci.City = ci_fr.City AND ci_fr.Lang = 'FR'
    LEFT JOIN l2.refdata_city_names ci_en ON ci.City = ci_en.City AND ci_en.Lang = 'EN'
    LEFT JOIN l2.refdata_country_names cn_fr ON ci.Country = cn_fr.Country AND cn_fr.Lang = 'FR'
    LEFT JOIN l2.refdata_country_names cn_en ON ci.Country = cn_en.Country AND cn_en.Lang = 'EN';

CREATE VIEW l3.view_airports AS
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
    l2.refdata_airports a
    LEFT JOIN l2.refdata_airport_names an_fr ON a.Airport = an_fr.Airport AND an_fr.Lang = 'FR'
    LEFT JOIN l2.refdata_airport_names an_en ON a.Airport = an_en.Airport AND an_en.Lang = 'EN'
    LEFT JOIN l2.refdata_city_names ci_fr ON a.City = ci_fr.City AND ci_fr.Lang = 'FR'
    LEFT JOIN l2.refdata_city_names ci_en ON a.City = ci_en.City AND ci_en.Lang = 'EN'
    LEFT JOIN l2.refdata_country_names cn_fr ON a.Country = cn_fr.Country AND cn_fr.Lang = 'FR'
    LEFT JOIN l2.refdata_country_names cn_en ON a.Country = cn_en.Country AND cn_en.Lang = 'EN';

CREATE VIEW l3.view_airports_sample AS
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
    l2.refdata_airports a
    LEFT JOIN l2.refdata_airport_names an_fr ON a.Airport = an_fr.Airport AND an_fr.Lang = 'FR'
    LEFT JOIN l2.refdata_airport_names an_en ON a.Airport = an_en.Airport AND an_en.Lang = 'EN'
    LEFT JOIN l2.refdata_city_names ci_fr ON a.City = ci_fr.City AND ci_fr.Lang = 'FR'
    LEFT JOIN l2.refdata_city_names ci_en ON a.City = ci_en.City AND ci_en.Lang = 'EN'
    LEFT JOIN l2.refdata_country_names cn_fr ON a.Country = cn_fr.Country AND cn_fr.Lang = 'FR'
    LEFT JOIN l2.refdata_country_names cn_en ON a.Country = cn_en.Country AND cn_en.Lang = 'EN'
WHERE a.Airport IN  (
  'IATA','DMM','DXB','PVG','BKK','IST','HND','PEK','DEL','CAI',
  'CMN','CPT','LOS','ALG','NBO','SSH','MRU','ATL','DFW','DEN',
  'ORD','LAX','JFK','LAS','MIA','MCO','CLT','MEX','SEA','EWR',
  'SFO','BOG','GRU','FRA','MUC','BER','AMS','LHR','MAN','OSL',
  'ARN','MAD','LIS','FCO','ATH','WAW','VIE','ZRH','DUB','NCE',
  'CDG')
;

CREATE VIEW l3.view_airlines AS
SELECT
    al.AirlineID,
    al.AirlineID_ICAO AS "AirlineICAO",
    an_fr.Name AS "AirlineNameFR",
    an_en.Name AS "AirlineNameEN"
FROM
    l2.refdata_airlines al
    LEFT JOIN l2.refdata_airline_names an_fr ON al.AirlineID = an_fr.Airline AND an_fr.Lang = 'FR'
    LEFT JOIN l2.refdata_airline_names an_en ON al.AirlineID = an_en.Airline AND an_en.Lang = 'EN';

CREATE VIEW l3.view_aircrafts AS
SELECT
    ac.aircraftCode AS "AircraftCode",
    an_fr.Name AS "AircraftNameFR",
    an_en.Name AS "AircraftNameEN",
    ac.AirlineEquipCode AS "AircraftEquipCode"
FROM
    l2.refdata_aircraft ac
    LEFT JOIN l2.refdata_aircraft_names an_fr ON ac.aircraftCode = an_fr.Aircraft AND an_fr.Lang = 'FR'
    LEFT JOIN l2.refdata_aircraft_names an_en ON ac.aircraftCode = an_en.Aircraft AND an_en.Lang = 'EN';

-- -------------------- --
-- CUSTOMER FLIGHT INFO --
-- -------------------- --

-- --------------- --
-- RAW TABLES (L1) --
-- --------------- --
-- DELETE RAW TABLE IF IT ALREADY EXISTS
DROP TABLE IF EXISTS l1.operations_customer_flight_info;

CREATE TABLE IF NOT EXISTS l1.operations_customer_flight_info (
    id SERIAL PRIMARY KEY,
    data JSONB NOT NULL
);

-- ------------------ --
-- COOKED TABLES (L2) --
-- ------------------ --
-- DELETE COOKED TABLE IF IT ALREADY EXISTS
DROP TABLE IF EXISTS l2.operations_customer_flight_info;

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


CREATE TABLE IF NOT EXISTS l2.operations_customer_flight_info (
    id SERIAL PRIMARY KEY,
    departure_airport_code CHAR(3) NOT NULL REFERENCES l2.refdata_airports(airport),
    departure_scheduled_datetime TIMESTAMP,
    departure_estimated_datetime TIMESTAMP,
    departure_actual_datetime TIMESTAMP,
    departure_terminal_name TEXT,
    departure_terminal_gate TEXT,
    departure_status_code departure_flight_code,
    departure_status_description TEXT,
    arrival_airport_code CHAR(3) NOT NULL REFERENCES l2.refdata_airports(airport),
    arrival_scheduled_datetime TIMESTAMP,
    arrival_estimated_datetime TIMESTAMP,
    arrival_actual_datetime TIMESTAMP,
    arrival_terminal_name TEXT,
    arrival_terminal_gate TEXT,
    arrival_status_code arrival_flight_code,
    arrival_status_description TEXT,
    operating_airline_id CHAR(3) NOT NULL REFERENCES l2.refdata_airlines(airlineid),
    operating_flight_nb INTEGER,
    equipment_aircraft_code CHAR(3),
    overall_status_code overall_flight_code,
    overall_status_description TEXT
);
