# Replication PostgresDB

## Notes

I have tried:

- DLT: Scripts are not functional
- Airbyte: Too heavy for my RAM


## Objectif:

In order to create a replication of some tables (ex. schema `l1`) in the PostgresDB, using the [logical replication feature](https://www.postgresql.org/docs/16/logical-replication.html) (which is a CDC method base in reading the stream of [WAL](https://www.postgresql.org/docs/16/wal-intro.html))


## With Airbyte

### Change the config parameters and restart the primary server

In the file postgres.conf in /var/lib/postgresql/data

- `wal_level = logical` (default is replica)
- `max_wal_senders = 10` (default)
- `max_replication_slots = 10` (default)

Restart the server (how to do it in the docker? just restart de contaier?)

*test_pub* references the publisher (primary server), and *test_sub* the subscriber server (backup).

## Create a user with LOGIN REPLICATION rights

```sql
CREATE USER airbyte_replication_user PASSWORD 'airbyteReplication';
GRANT USAGE ON SCHEMA l1 TO airbyte_replication_user;
GRANT SELECT ON ALL TABLES IN SCHEMA l1 TO airbyte_replication_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA l1 GRANT SELECT ON TABLES TO airbyte_replication_user;
ALTER USER airbyte_replication_user REPLICATION;
```

### Create a Postgres Source from the UI


### Create a publication

```sql
-- Create a publication
test_pub=# CREATE PUBLICATION airbyte_publication FOR TABLE <tbl1, tbl2, tbl3>;
test_pub=# CREATE PUBLICATION pub1 FOR ALL TABLES;
test_pub=# CREATE PUBLICATION pub1 FOR TABLES IN SCHEMA ... ;
-- You can ADD or DROP table from am existing publication
ALTER PUBLICATION ... ADD / DROP TABLE ...
```

#### Create replication identities for tables

Published tables must have a *replica identity* configured, to be able to replicate UPDATE and DELETE operations.


```sql
-- If table has a primary key
ALTER TABLE tbl1 REPLICA IDENTITY DEFAULT;
-- If table has no primary key (all row is used)
ALTER TABLE tbl1 REPLICA IDENTITY FULL;
```

### Create a subscription

In the subscriber server create a subscription. The slot can be automatically created in the publisher or we can do it manually.



## Steps followed with DLT

[dlt docs postgres replication](https://dlthub.com/docs/dlt-ecosystem/verified-sources/pg_replication)

### Setup postgres conf

In file `/var/lib/postgresql/data/postgresql.conf`, set the parameter: 

- `wal_level = logical`


### Setup user

```sql
CREATE ROLE replication_role WITH LOGIN REPLICATION;
GRANT USAGE ON SCHEMA l1 TO replication_role;
GRANT SELECT ON ALL TABLES IN SCHEMA l1 TO replication_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA l1 GRANT SELECT ON TABLES TO replication_role;
CREATE USER replication_user PASSWORD 'replication_pass';
GRAN replication_role TO replication_user;
```

```sql
ALTER TABLE l1.refdata_aircraft REPLICA IDENTITY DEFAULT;
ALTER TABLE l1.flight_schedules REPLICA IDENTITY FULL;
```

### Initialize source

```bash
dlt init pg_replication duckdb
dlt init sql_database duckdb
pip install -r requirements.txt
python pg_replication_pipeline.py
