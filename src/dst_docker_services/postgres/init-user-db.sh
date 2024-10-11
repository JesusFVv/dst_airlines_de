#!/usr/bin/env bash
# Initialise reader user and users privileges
# This script is launched if not previous persistent volume exists
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON SCHEMA public TO $POSTGRES_USER;    
	CREATE USER dst_reader with PASSWORD 'pass_reader';
    GRANT CONNECT, TEMPORARY ON DATABASE $POSTGRES_DB TO dst_reader;
    GRANT USAGE ON SCHEMA public TO dst_reader;
    ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER IN SCHEMA public GRANT SELECT ON TABLES TO dst_reader;
EOSQL

# GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $POSTGRES_USER;
# ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $POSTGRES_USER;
# GRANT SELECT ON ALL TABLES IN SCHEMA public TO dst_reader GRANTED BY $POSTGRES_USER;

# Create role and User for the PostgREST API
# Create anonimous role to grant read acces to the specified schema and tables of the DB, for the web requests.
# Create an user in order to login to the RESTAPI
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    create role web_anonimous nologin;
    grant usage on schema public to web_anonimous;
    grant select on all tables in schema public to web_anonimous;
    create role postgrest_authenticator noinherit login password 'pass_api';
    grant web_anonimous to postgrest_authenticator;
EOSQL
