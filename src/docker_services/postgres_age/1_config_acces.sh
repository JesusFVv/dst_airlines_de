#!/usr/bin/env bash
# Updates conf of acces for the GraphDB
# Postgres Server should listen to other hosts with IP: 172.0.0.0/8 (mainly other docker containers)
# First delete the last line, wich by default gives privileges 'host all all all pass'
sed -i '$ d' /var/lib/postgresql/data/pg_hba.conf
# Then allow only hosts with IPs 172.0.0.0/8
echo "host all all 172.0.0.0/8 trust" >> /var/lib/postgresql/data/pg_hba.conf

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    select pg_reload_conf();
EOSQL
