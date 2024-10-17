from typing import Any, Optional
import itertools

import dlt
from dlt.common.pendulum import pendulum
from dlt.sources.rest_api import (
    RESTAPIConfig,
    rest_api_source,
)
from dlt.sources.helpers.rest_client.auth import OAuth2ClientCredentials
from dlt.pipeline.exceptions import PipelineStepFailed
import pandas as pd

BASE_URL = dlt.config["sources.lufthansa_api.base_url"]
ACCES_TOKEN_URL = dlt.secrets["source.lufthansaAPI.acces_token_url"]
CLIENT_ID = dlt.secrets["source.lufthansaAPI.flight_schedules_cliend_id"]
CLIENT_SECRET = dlt.secrets["source.lufthansaAPI.flight_schedules_cliend_secret"]


def load_flight_schedules(origin: str, destination: str, date_search: str) -> None:
    """
    
    """
    config: RESTAPIConfig = {
            "client": {
                "base_url": BASE_URL,
                "auth": 
                    OAuth2ClientCredentials(
                        access_token_url=ACCES_TOKEN_URL,
                        client_id=CLIENT_ID,
                        client_secret=CLIENT_SECRET,
                        access_token_request_data={"grant_type": "client_credentials",},
                    ),
            },
            "resource_defaults": {
                "write_disposition": "append",
                "endpoint": {
                    "params": {
                        # "limit": 3,
                    },
                },
            },
            "resources": [
                {
                    "name": "flight_schedules",
                    "endpoint": {
                        "path": "operations/schedules/{origin}/{destination}/{fromDateTime}",
                        "method": "GET",
                        "params": {
                            "origin": origin,
                            "destination": destination,
                            "fromDateTime": date_search,
                            "directFlights": "true",
                        },
                        "data_selector": "ScheduleResource.Schedule",
                        "paginator": {
                            "type": "offset",
                            "limit": 100,
                            "offset": 0,
                            "maximum_offset": 10,
                            "total_path": None
                        },
                        "response_actions": [
                            {"status_code": 404, "action": "ignore"},
                            # {"status_code": 403, "content": "Rate Limit Exceeded", "action": "ignore"},
                            # {"status_code": 403, "content": "Account Over Rate Limit", "action": "ignore"},
                            # {"status_code": 403, "content": "Account Over Queries Per Second Limit", "action": "ignore"},
                            # {"status_code": 403, "content": "Account Inactive", "action": "ignore"},
                        ],
                    },
                    "selected": True,
                }
            ],
    }
    flight_schedules_source = rest_api_source(config)
    pipeline = dlt.pipeline(
        pipeline_name="extract_flight_schedules_lufthansa_API",
        destination="postgres",  # Postgres conection settings are defined in the secrets.toml
        dataset_name=dlt.secrets["destination.postgres.credentials.schema"], # Schema name in Postgres DB
    )
    
    try:
        load_info = pipeline.run(flight_schedules_source)
    except PipelineStepFailed as e:
        print(e)
        if "403" in e.args[0]:
            raise ValueError("403 Client Error", 403)
        else:
            raise e
    else:
        print(load_info) 


def get_flight_routes() -> Any:
    """
    - Load the list of airports
    - Create routes for all the possible combination
    """
    airports_file_path = "/home/ubuntu/dst_airlines_de/data/airports/airports.csv"
    with open(airports_file_path, "r", encoding="utf-8") as file:
        file.readline()
        airports = file.readlines()
    airports = list(map(lambda x: x.strip(), airports))     
    return itertools.product(airports, airports)
    

def main() -> None:
    end_date_search = pendulum.today().add(days=3)
    add_days = 0
    while True:
        add_days += 1
        date_search = pendulum.today().add(days=add_days)
        if date_search > end_date_search:
            break
        else:
            for origin, destination in get_flight_routes():
                if origin == destination:
                    continue
                else:
                    print(f"Origin: {origin} to Destination: {destination}")
                    load_flight_schedules(origin, destination, date_search.to_date_string())
        

if __name__ == "__main__":
    main()
