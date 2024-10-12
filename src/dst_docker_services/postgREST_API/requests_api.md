# Start querying the DB through the API

HTTP_API = http://{VM_IP}:8000/postgrest_api/
HTTPS_API = https://{VM_IP}:8085/postgrest_api/

```bash
# List all the cities & countries in the DB
curl "http://localhost:3000/refdata_cities_coo"
# List the cities for the country France (country=FR)
curl "http://localhost:3000/refdata_cities_coo?country=eq.FR"
# Count the number of cities for the country France
curl "http://localhost:3000/refdata_cities_coo?country=eq.FR&select=count()"
# Count the number of cities by country in the DB
curl "http://localhost:3000/refdata_cities_coo?select=count(),country"
```