# NGINX

In order to secure the acces to the different http applications we use a reverse proxy, ideally with https acces. This allow us to not expose the applications directly on the internet.

## Installation

```bash
docker run --name nginx \
-v /etc/nginx/conf:/etc/nginx:ro \
--mount type=bind,source=/var/nginx/www,target=/usr/share/nginx/html,readonly \
--network dst_network -p 8080:80 --restart unless-stopped \
-d nginx
```

```bash
docker run --name nginx \
--network dst_network -p 8080:80 --restart unless-stopped \
-d nginx
```

## Configuration

Configuration files are located in Host in `/var/nginx/conf`.

To reload the NGINX configuration, send the HUP signal to Docker:

```bash
docker kill -s HUP container-name
```

## Logs

```bash
docker logs -f nginx
```

## Create SSL certificate

SSL certificate are needed for the HTTPS acces. To create a new certificate, run the following command:

```bash
PROJECT_ABSOLUT_PATH=/home/ubuntu/dst_airlines_de
sudo openssl req -newkey rsa:4096 \
    -x509 \
    -sha256 \
    -days 3650 \
    -nodes \
    -out ${PROJECT_ABSOLUT_PATH}/etc/ssl/certs/dst_vm2.crt \
    -keyout ${PROJECT_ABSOLUT_PATH}/etc/ssl/certs/dst_vm2.key \
    -subj "/C=FR/ST=Paris/L=Paris/O=SAE/OU=IT Department/CN=server dst project"
```

## Check connection to the apps

```bash
# HTTP version, work in browser and CLI
curl --fail -I http://63.35.176.208:8080/metabase/
curl --fail -I http://63.35.176.208:8080/cloudbeaver/

# The HTTPS version work in CLI but not in the browser of the SAE PC
curl --insecure --fail -I https://63.35.176.208:8085/metabase/
curl --insecure --fail -I https://63.35.176.208:8085/cloudbeaver/
```

## Acces to the apps with the browser

CloudBeaver: http://63.35.176.208:8080/cloudbeaver/
Metabase: http://63.35.176.208:8080/metabase/
