# NGINX

In order to secure the acces to the different http applications we use a reverse proxy, ideally with https acces. This allow us to not expose the applications directly on the internet.

## Installation

```bash
docker run --name nginx --network dst_network -p 8080:80 -d nginx
```