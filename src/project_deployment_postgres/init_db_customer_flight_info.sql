-- ---------- --
-- RAW TABLES --
-- ---------- --

-- DELETE RAW TABLE IF IT ALREADY EXISTS
DROP TABLE IF EXISTS public.operations_customer_flight_info_raw;

CREATE TABLE IF NOT EXISTS public.operations_customer_flight_info_raw (
    id SERIAL PRIMARY KEY,
    data JSONB
);


-- ------------- --
-- COOKED TABLES --
-- ------------- --

-- DELETE COOKED TABLE IF IT ALREADY EXISTS
DROP TABLE IF EXISTS public.operations_customer_flight_info_coo;

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


CREATE TABLE IF NOT EXISTS public.operations_customer_flight_info_coo (
    departure_airport_code char(3),
    departure_scheduled_datetime timestamp,
    departure_estimated_datetime timestamp,
    departure_actual_datetime timestamp,
    departure_terminal_name text,
    departure_terminal_gate text,
    departure_status_code departure_flight_code,
    departure_status_description text,
    arrival_airport_code char(3),
    arrival_scheduled_datetime timestamp,
    arrival_estimated_datetime timestamp,
    arrival_actual_datetime timestamp,
    arrival_terminal_name text,
    arrival_terminal_gate text,
    arrival_status_code arrival_flight_code,
    arrival_status_description text,
    operating_airline_id char(2),
    operating_flight_nb integer,
    equipment_aircraft_code char(3),
    overall_status_code overall_flight_code,
    overall_status_description text,
    collect_date date,
    CONSTRAINT customer_flight_info_pkey PRIMARY KEY(operating_airline_id, operating_flight_nb)
);
