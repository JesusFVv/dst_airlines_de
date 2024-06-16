#!/usr/bin/env bash
# Deploy postgres for the DS Airlines project

# DEPLOY:
# Use the image: postgres:16.3-bullseye & the docker-compose.yml file
# Define super user: ds_airlines_designer
# Define the password and the authentification method as: scram-sha-256 (no trust)
# Define the data base name: ds_airlines
# Run the containers
docker compose up -d
# Secrets with password and user are stored in /run/secrets (with all-reads permissions)
# To improve security, implement no trust for connexions within the container, to do that:
# Connect inside the container and find the file pg_hba.conf
find / -name 'pg_hba.conf'  # -> /var/lib/postgresql/data/pg_hba.conf
nano /var/lib/postgresql/data/pg_hba.conf
# Change trust -> scram-sha-256 for the lines: 'host all all (blank) trust' and 'host all all 127.0.0.1/32 trust'
# Then reload postgresql service with the new pg_hba.conf, connect to the psql cli and execute pg_reload_conf()
psql -U $POSTGRES_USER
select pg_reload_conf();
# The next time you try to connect to psql cli from within the container, it will ask for the password

# CONNECTION TO DB using DBeaver:
# To open a connection with DBeaver Cloud use (host: postgres_db, dbase: dst_airlines_db, & user and pass)
# Designer role has all privileges and Reader role has read only on tables.
