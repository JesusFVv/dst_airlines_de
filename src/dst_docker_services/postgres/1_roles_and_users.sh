#!/usr/bin/env bash
# Initialise reader user and users privileges
# This script is launched if not previous persistent volume exists

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON SCHEMA public TO $POSTGRES_USER;    
	CREATE ROLE $POSTGRES_DB_READER WITH LOGIN PASSWORD '$POSTRES_READRE_PASS';
    GRANT CONNECT, TEMPORARY ON DATABASE $POSTGRES_DB TO $POSTGRES_DB_READER;
    GRANT USAGE ON SCHEMA public TO $POSTGRES_DB_READER;
    ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER IN SCHEMA public GRANT SELECT ON TABLES TO $POSTGRES_DB_READER;
EOSQL

# GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $POSTGRES_USER;
# ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $POSTGRES_USER;
# GRANT SELECT ON ALL TABLES IN SCHEMA public TO dst_reader GRANTED BY $POSTGRES_USER;

# Create roles and users
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE ROLE $PGRST_DB_ANON_ROLE  WITH NOLOGIN;
    CREATE ROLE $PGRST_DB_USER WITH LOGIN PASSWORD '$PGRST_USER_PASS';
    CREATE ROLE $REPLICATION_DB_ROLE WITH NOLOGIN REPLICATION;
    CREATE ROLE $REPLICATION_DB_USER WITH LOGIN PASSWORD '$REPLICATION_USER_PASS';
EOSQL


# Postgres Server should listen to other hosts with IP: 172.0.0.0/8 (mainly other docker containers)
# First delete the last line, wich by default gives privileges 'host all all all pass'
sed -i '$ d' /var/lib/postgresql/data/pg_hba.conf
# Then allow only hosts with IPs 172.0.0.0/8
echo "host all all 172.0.0.0/8 scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    select pg_reload_conf();
EOSQL
