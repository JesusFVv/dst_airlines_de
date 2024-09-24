# dst_airlines_de
Project Datascientest Danta Engineer


## Steps pour populer les tables
 
```bash
pushd src/project_deployment_postgres
docker-compose up -d && popd
 
pushd bin/reference_data/raw_loading
./run_docker.sh && popd
 
pushd bin/customer_flight_info/raw_loading
./run_docker.sh && popd
 
pushd bin/customer_flight_info/cooked_loading
./run_docker.sh && popd
```
Dbeaver
user: cbadmin
pass: cbAdmin1234
Postgres
db: dst_airlines_db
dst_designer
Vtd1lDNZlwY3DM4h2j7V