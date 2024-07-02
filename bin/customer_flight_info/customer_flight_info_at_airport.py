import datetime as dt
import json
import logging
import numpy as np
import pandas as pd
import requests
import time
import urllib3
from pathlib import Path, PosixPath
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry


BASE_URL = r"https://api.lufthansa.com/v1/"
TOKEN_ENDPOINT = BASE_URL + r"oauth/token"
CLIENT_ID = r"u7qmdgrkcybgrjfkdwqy94u55"
CLIENT_SECRET = r"W5VeMhayy2"

CUSTOMER_FLIGHT_INFO_DEPARTURE_AIRPORT_ENDPOINT = (
    BASE_URL + r"operations/customerflightinformation/departures/{}/{}"
)
CUSTOMER_FLIGHT_INFO_ARRIVAL_AIRPORT_ENDPOINT = (
    BASE_URL + r"operations/customerflightinformation/arrivals/{}/{}"
)


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

# Create handlers
# c_handler = logging.StreamHandler()
# c_handler.setLevel(logging.INFO)
# f_handler = logging.FileHandler("error.log")
# f_handler.setLevel(logging.ERROR)

# # Add handlers to the logger
# logger.addHandler(c_handler)
# logger.addHandler(f_handler)


def get_airports(filename: PosixPath) -> np.ndarray:
    """Read a CSV file and return data written in IATA column

    Args:
        filename (PosixPath): path of the file to be read

    Returns:
        np.ndarray: a numpy array containing airports iata code
    """

    df = pd.read_csv(filename, sep=";", usecols=["IATA"])
    return df["IATA"].values


def generate_datetime_array(
    start_date: str, stop_date: str, increment_value: str = "4h"
) -> np.ndarray:
    """Generate a numpy array of datetime string from start_date (included) to stop_date (excluded) with a delta of increment_value

    Args:
        start_date (str): first datetime value YYYY-mm-dd HH:MM:SS
        stop_date (str): last datetime value YYYY-mm-dd
        increment_value (str): delta value between each datetime

    Returns:
        np.ndarray: a numpy array containing datetime string
    """

    df = pd.DataFrame(
        pd.date_range(
            start=start_date, end=stop_date, freq=increment_value, inclusive="left"
        ),
        columns=["date_time"],
    )
    df["date_time"] = df["date_time"].dt.strftime(
        "%Y-%m-%dT%H:%M"
    )  # Format datetime to match with expected input in the endpoint

    return df["date_time"].values


def get_token() -> tuple[str, int]:
    """Get API token

    Returns:
        access_token (str): API access token
        expires_in (int): the number of seconds until this token expires
    """

    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    # Request data
    data = {
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "grant_type": "client_credentials",
    }
    try:
        # res = session.post(TOKEN_ENDPOINT, data=data, headers=headers)
        res = requests.post(TOKEN_ENDPOINT, data=data, headers=headers)
    except Exception:
        raise ValueError(f"Can't reach {TOKEN_ENDPOINT}")
    else:
        if res.status_code == 200:
            access_token, expires_in = (
                res.json()["access_token"],
                res.json()["expires_in"],
            )
            return access_token, expires_in
        else:
            raise ValueError("Can't get access token")


def customer_flight_information_airport(
    session: requests.sessions.Session, endpoint: str, token: str
) -> dict | None:
    """Get results from endpoint parameter

    Args:
        session (requests.sessions.Session): a Session object
        endpoint (str): endpoint URL to be requested
        token (str): API access token

    Returns:
        data (dict|None): endpoint results or None if endpoint is not available
    """

    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }

    # Request parameters
    params = {
        "limit": None,  # integer, number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken)
        "offset": None,  # integer, number of records skipped. Defaults to 0
    }

    logger.info(f"Querying {endpoint}")
    try:
        res = session.get(endpoint, params=params, headers=headers, timeout=1)
        match res.status_code:
            case 200:
                logger.info(f"HTTP code {res.status_code} for endpoint {res.url}")
                data = res.json()
            # case 404:
            #     logger.warning(f"HTTP error {res.status_code} for endpoint {res.url}")
            #     data = None
            case _:
                logger.warning(f"HTTP error {res.status_code} for endpoint {res.url}")
                data = None
        return data
    except (requests.exceptions.ConnectionError, requests.exceptions.ReadTimeout):
        # logger.exception(f"Endpoint {endpoint} is not reachable")
        logger.warning(f"Endpoint {endpoint} is not reachable")
        return
    except (
        urllib3.exceptions.MaxRetryError,
        requests.exceptions.RetryError,
        requests.exceptions.ConnectionError,
    ):
        # logger.exception(f"Max retries has been reached for endpoint {endpoint}")
        logger.warning(f"Max retries has been reached for endpoint {endpoint}")
        return


def save_data(
    data: dict, endpoint_name: str, working_dir: PosixPath, date_time: str, iata_code: str
) -> None:
    """Save data in JSON format in a output folder

    Args:
        data (dict): data to be saved (endpoint results)
        endpoint_name (str): a keyword to differentiate the different endpoints
        working_dir (PosixPath): working directory path
        date_time (str): datetime string YYYY-mm-ddTHH:MM
        iata_code (str): airport iata code
    """
    query_date = date_time.split("T")[0]
    output_filepath = Path(
        working_dir,
        "output",
        query_date,
        f"{iata_code}_{endpoint_name}_{date_time}.json",
    )
    output_filepath.parent.mkdir(
        exist_ok=True, parents=True
    )  # Create folders if they do not exist
    with open(output_filepath, "w") as f:
        json.dump(data, f, ensure_ascii=True, indent=4)


if __name__ == "__main__":
    # Get airports array
    working_dir = Path.cwd()
    airport_filepath = Path(working_dir, "input", "airports.csv")
    airports = get_airports(airport_filepath)  # Numpy array
    logger.debug(airports)

    # Generate list of datetimes
    # This list starts yesterday at 2am since first flights seem to start at 6am and the API gives results from H-4
    yesterday = dt.date.today() - dt.timedelta(days=1)
    two_am = dt.time(hour=2, minute=0, second=0)
    yesterday_two_am = dt.datetime.combine(yesterday, two_am).strftime(
        "%Y-%m-%d %H:%M:%S"
    )
    today = dt.date.today().strftime("%Y-%m-%d")
    # datetime_array = generate_datetime_array(yesterday_two_am, today)
    datetime_array = generate_datetime_array("2024-06-26 02:00:00", today)
    logger.debug(datetime_array)
    
    # Define retry strategy for https requests
    session = (
        requests.Session()
    )  # a Session object allows to persist some parameters across requests
    retries = Retry(
        # total=2,
        total=7,
        backoff_factor=1,
        allowed_methods=["GET"],
        status_forcelist=[404, 429, 500, 502, 503, 504],
        raise_on_status=True,
    )
    session.mount("https://", HTTPAdapter(max_retries=retries))

    # Get token to be able to use API
    token, expiration_time = get_token()
    logger.info(f"Token granted for {int(expiration_time/3600)} hours!")
    print("\n")

    # Loop over airports
    unfound_airports = {}
    for iata_code in airports:
    # for iata_code in ["CDG"]:
        unfound_airports[iata_code] = 0
        # Loop over datetime for a given airport
        # datetime_array = ["2024-06-29T01:00", "2024-06-29T02:00"]
        for date_time in datetime_array:
            endpoint_name = "departure"
            res = customer_flight_information_airport(
                session,
                CUSTOMER_FLIGHT_INFO_DEPARTURE_AIRPORT_ENDPOINT.format(
                    iata_code, date_time
                ),
                token,
            )
            time.sleep(1)  # Free API is limited to 5 requests per second
            print("\n")
            if res is None:
                unfound_airports[iata_code] += 1
            else:
                break
                # save_data(res, endpoint_name, working_dir, date_time, iata_code)

            # endpoint_name = "arrival"
            # res = customer_flight_information_airport(
            #     session,
            #     CUSTOMER_FLIGHT_INFO_ARRIVAL_AIRPORT_ENDPOINT.format(
            #         iata_code, date_time
            #     ),
            #     token,
            # )
            # time.sleep(1)  # Free API is limited to 5 requests per second
            # if res is None:
            #     unfound_airports[iata_code] += 1
            # else:
            #     save_data(res, endpoint_name, working_dir, date_time, iata_code)

        if unfound_airports[iata_code] == len(datetime_array):
            logger.error(unfound_airports)
            missing_airport_filepath = Path(working_dir, "output", "missing_airports.txt")
            with open(missing_airport_filepath, "a") as f_airports:
                f_airports.write(iata_code + "\n")

    print("COLLECT COMPLETED !")
