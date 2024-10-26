# Back up Postgresql

## Using pg_dump

`pg_dump` will create a consistent snapshot of the DB at the time it began running. Without blocking other operations. It can create a backup file with all the SQL commands needed to reproduce the database.

```bash
# Creating a Dump
# Simple usage, dump to a file
pg_dump dbname > dumpfile
# with specific options
pg_dump <dbname> -U <PG_USER> -h <host> -p <port> -n <schema> -t <table>

# Restoring the Dump
# Simple restore
psql dbname < dumpfile

```

## Example for DST project

```bash
# Execute this commands in the VM terminal
# Create a dump of the database (if postgres client is installes)
pg_dump dst_airlines_db -U dst_designer -h localhost -p 5433 > tmp/sql_dump.sql
# Create a dump of the database (using docker) [PREFERRED]
docker exec -it postgres_dst pg_dump dst_airlines_db -U dst_designer -t l1.refdata_airlines > tmp/sql_dump.sql

```

## How to drop a user with privileges

[source](https://stackoverflow.com/questions/3023583/how-to-quickly-drop-a-user-with-existing-privileges)

```bash
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA myschem FROM user_mike;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA myschem FROM user_mike;
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA myschem FROM user_mike;
REVOKE ALL PRIVILEGES ON SCHEMA myschem FROM user_mike;
ALTER DEFAULT PRIVILEGES IN SCHEMA myschem REVOKE ALL ON SEQUENCES FROM user_mike;
ALTER DEFAULT PRIVILEGES IN SCHEMA myschem REVOKE ALL ON TABLES FROM user_mike;
ALTER DEFAULT PRIVILEGES IN SCHEMA myschem REVOKE ALL ON FUNCTIONS FROM user_mike;
REVOKE USAGE ON SCHEMA myschem FROM user_mike;
REASSIGN OWNED BY user_mike TO masteruser;
DROP USER user_mike ;
```

```bash
# Example to remove the user airbyte_replication_user (it owns nothing)
REVOKE ALL ON ALL TABLES IN SCHEMA l1 FROM airbyte_replication_user;
REVOKE ALL PRIVILEGES ON SCHEMA l1 FROM airbyte_replication_user;
REVOKE ALL PRIVILEGES ON DATABASE dst_airlines_db FROM airbyte_replication_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA L1 REVOKE ALL ON TABLES FROM airbyte_replication_user;
DROP USER airbyte_replication_user;
DROP ROLE airbyte_replication_user;

# Example to remove the user airbyte_replication_user (it owns nothing)
REVOKE ALL ON ALL TABLES IN SCHEMA l1 FROM airbyte_replication_user;
REVOKE ALL PRIVILEGES ON SCHEMA l1 FROM airbyte_replication_user;
REVOKE ALL PRIVILEGES ON DATABASE dst_airlines_db FROM airbyte_replication_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA L1 REVOKE ALL ON TABLES FROM airbyte_replication_user;
DROP USER airbyte_replication_user;
DROP ROLE airbyte_replication_user;
```