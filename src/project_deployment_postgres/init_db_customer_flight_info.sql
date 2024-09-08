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
    -- operating_airline_id CHAR(2) NOT NULL REFERENCES refdata_airlines_coo(airlineid) ON DELETE CASCADE,
    operating_airline_id CHAR(2) NOT NULL,
    operating_flight_nb INTEGER,
    equipment_aircraft_code CHAR(3),
    overall_status_code overall_flight_code,
    overall_status_description TEXT,
    CONSTRAINT customer_flight_info_pk
       PRIMARY KEY(operating_airline_id, operating_flight_nb, departure_scheduled_datetime)
);
