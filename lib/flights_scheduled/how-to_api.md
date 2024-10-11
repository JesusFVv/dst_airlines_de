# How to use Lufthansa API

## Generate a session token

url: https://api.lufthansa.com/v1/oauth/token
client_id=xpavg4z64mqt5wyystzh6953k
client_secret=U724kV9JW2
grant_type=client_credentials
header = Content-Type: application/x-www-form-urlencoded

```bash
curl "https://api.lufthansa.com/v1/oauth/token" -X POST -d "client_id=xpavg4z64mqt5wyystzh6953k" -d "client_secret=U724kV9JW2" -d "grant_type=client_credentials"

Response example:
{"access_token":"d8bmzggu72dy69tzkffe6vaa","token_type":"bearer","expires_in":21600}
```

## Query the end point

```bash
GET https://api.lufthansa.com/v1/operations/schedules/{origin}/{destination}/{fromDateTime}[?directFlights=true]
```

Or, example with curl command
```bash
curl -H "Authorization: Bearer b2d5h7n4chvpun2f4pu7jh36" -H "Accept: application/json" https://api.lufthansa.com/v1/mds-references/airports/FRA
```

