
docker run \
    -d \
    --name nginx-lea \
    -p 1033:1033 \
    -p 443:443 \
    --net "turing-network" \
    --restart "unless-stopped" \
    -v /appl/nginx/site-available.conf:/etc/nginx/conf.d/nginx.conf \
    -v /appl/nginx/nginx.conf:/etc/nginx/nginx.conf \
    -v /appl/nginx/certs:/etc/nginx/ssl \
    nginx