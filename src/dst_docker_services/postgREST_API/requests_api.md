# Start querying the DB through the API

HTTP_API = http://{VM_IP}:8000/postgrest_api/
HTTPS_API = https://{VM_IP}:8085/postgrest_api/

URL depending on:
- If inside the PostgREST API container: http://localhost:3000/
- If from the host: http://localhost:8000/postgrest_api/
- If from the internet: http://{VM_IP}:8000/postgrest_api/

```bash
# List all the cities & countries in the DB
curl "http://localhost:8000/postgrest_api/refdata_cities"
# List the cities for the country France (country=FR)
curl "http://localhost:8000/postgrest_api/refdata_cities?country=eq.FR"
# Count the number of cities for the country France
curl "http://localhost:8000/postgrest_api/refdata_cities?country=eq.FR&select=count()"
# Count the number of cities by country in the DB
curl "http://localhost:8000/postgrest_api/refdata_cities?select=count(),country"

curl "http://localhost:8000/postgrest_api/operations_customer_flight_info?departure_actual_datetime=not.is.null" \
  -H "Accept-Profile: l2" | wc -l

curl "http://localhost:8000/postgrest_api/operations_customer_flight_info" \
  -H "Accept-Profile: l2" | wc -l

headers = {'Accept-Profile': 'l2'}  # Define the schema of the table (l2 or l3)
r = requests.get('http://nginx:80/postgrest_api/refdata_cities', headers=headers)
```