# Back up Postgresql

## Using pg_dump

`pg_dump` will create a consistent snapshot of the DB at the time it began running. Without blocking other operations. It can create a backup file with all the SQL commands needed to reproduce the database.

```bash
# Creating a Dump
# Simple usage, dump to a file
pg_dump dbname > dumpfile
# with specific options and gzip compression
pg_dump <dbname> -U <PG_USER> -h <host> -p <port> -n <schema> -t <table> | gzip > dumpfile

# Restoring the Dump
# Simple restore
psql dbname < dumpfile
# Restore if compressed
gunzip -c dumpfile | psql $POSTGRES_DB -U dst_designer
```

## Example for DST project

```bash
# Dump
FILE_NAME=$(date +%Y%m%d_%H%M%S_)dst_airlines_db_dump.sql.gz
docker exec $POSTGRES_CONTAINER_NAME sh -c "pg_dump $POSTGRES_DB -U dst_designer | gzip > /var/backups/$FILE_NAME"
# Restore
FILE_NAME=$0
docker exec $POSTGRES_CONTAINER_NAME sh -c "gunzip -c /var/backups/${FILE_NAME} | psql $POSTGRES_DB -U dst_designer"
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