-- Suppression des tables si elles existent déjà
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