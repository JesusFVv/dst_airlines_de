# Metabase

## Install
How to configure the [Metabase Docker](https://www.metabase.com/docs/latest/installation-and-operation/running-metabase-on-docker#docker-specific-environment-variables).

```bash
PROJECT_DIR=/home/ubuntu/dst_airlines_de
# Pull image
docker pull metabase/metabase:latest
# Run container
# docker run -d -p 3000:3000 --network=dst_network --name metabase metabase/metabase
# With db persisted in file
docker run --name metabase \
-v "${PROJECT_DIR}"/var/metabase/data:/metabase-data \
-e MB_DB_FILE=/metabase-data/metabase.db -e MUID=$UID -e MGID=$GID \
-e "JAVA_TIMEZONE=Europe/Paris" -e "JAVA_OPTS=-Xmx3g" \
-e MB_JETTY_HOST=0.0.0.0 -e MB_JETTY_PORT=3000 \
-p 3000:3000 --network dst_network --restart no \
-d metabase/metabase

# See the logs
docker logs -f metabase
# Test metabase (inside the container)
curl --fail -I http://localhost:3000/api/health || exit 1
```

## How to connect to Metabase

In the browser, go to http://{VM-IP}:3000 or to http://localhost:3000 if the port has been forwarded from the VM.

## Credentials

Jesus email/pass: jfv@sae.com / D?.boiLW$7/0,0L~Y=
Christophe email/pass: cm@sae.com / JOkE6m8eqGzVWq
Alexandre email/pass: am@sae.com / 9-9qTyh8dmirRH


## Ceate a connection to our PostgreSQL DB

host: `postgres_dst`
port: `5432`
db name: `dst_airlines_db`
user: `dst_reader`
password: 

