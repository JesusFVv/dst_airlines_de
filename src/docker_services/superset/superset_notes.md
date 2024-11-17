# Superset notes

[Launch superset with docker compose](https://superset.apache.org/docs/installation/docker-compose/).

Just launch the docker-compose.yml in the superset directory (`~/tmp/superset`).

Before launching, in the docker-compose file, we must change the exposed port for the NGINX service from 80 to 9000.

Steps

```bash
git clone --depth=1  https://github.com/apache/superset.git
docker compose up -d
```
## Reverse proxy with Nginx

I can not reverse proxy with NGINX in a modified rootURI (the base root for superset can not be upated).
The only solution I found was to left superset as root ("/") in the NGINX config.

## Connection
To launch in the browser superset go to URL: `http://{VM_IP}:8000/`, Nginx is redirecting the request to superset.

First time connecting, *user / pass = admin / amdin*

## Create in Superset a DB connection to our Postgres DB

The connections goes through NGNIX and the TCP stream created at: `http://{VM_IP}:5433/`

- db host : {VM_IP}
- db port : 5433



