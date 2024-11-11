FILE_NAME='xxx'
gunzip -c var/db_dumps/graph_db/$FILE_NAME > src/docker_services/postgres_age/docker_entrypoint_scripts/2_schemas_tables_and_data.sql

# IMPORTANT, ALWAYS COMMENT THE LINE 23 in the sql file
# -- CREATE SCHEMA ag_catalog;