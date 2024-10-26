#!/usr/bin/env python
""" Functions needed for the pipeline of the endpoint customer flight info
"""
from pathlib import PosixPath
import logging
from collections.abc import Generator

import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry
import tomli
from common import utils
from psycopg2.extras import Json
import psycopg2


logger = logging.getLogger(__name__)

with open('secrets.toml', mode='rb') as fp:
    config = tomli.load(fp)

TOKEN_ENDPOINT = config['source']['lufthansaAPI']['acces_token_url']
CLIENT_ID = config['source']['lufthansaAPI']['client_flight_info_client_id']
CLIENT_SECRET = config['source']['lufthansaAPI']['client_flight_info_client_secret']
CUSTOMER_FLIGHT_INFO_DEPARTURE_AIRPORT_ENDPOINT = config['source']['lufthansaAPI']['customer_flight_info_departures_url']
CUSTOMER_FLIGHT_INFO_ARRIVAL_AIRPORT_ENDPOINT = config['source']['lufthansaAPI']['customer_flight_info_arrivals_url']

class TokenException(Exception):
    pass


class EndPointException(Exception):
    pass


def get_token() -> tuple[str, int]:
    """Get API token

    Returns:
        access_token (str): API access token
        expires_in (int): the number of seconds until this token expires
    """
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    data = {
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "grant_type": "client_credentials",
    }
    try:
        res = requests.post(TOKEN_ENDPOINT, data=data, headers=headers)
    except Exception as e:
        logging.error(e)
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


def customer_flight_information_airport(session: requests.sessions.Session, 
                                        endpoint: str, token: str) -> dict:
    """Get results from endpoint parameter

    Args:
        session (requests.sessions.Session): _description_
        endpoint (str): _description_
        token (str): _description_

    Raises:
        EndPointException: _description_
        EndPointException: _description_

    Returns:
        dict: endpoint results or None if endpoint is not available
    """
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    params = {
        "limit": 100,  # integer, number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken)
        "offset": None,  # integer, number of records skipped. Defaults to 0
    }
    logger.debug(f"Querying {endpoint}")
    try:
        res = session.get(endpoint, params=params, headers=headers)
    except Exception as e:
        logger.error(f"HTTP error {res.status_code} for endpoint {res.url}")
        logger.error(e)
        raise  ValueError("Unknown Exception. Please Investigate.", 0)
    else:
        if res.status_code == 200:
            logger.debug(f"HTTP code {res.status_code} for endpoint {res.url}")
            data = res.json()
        elif res.status_code == 403:
            raise ValueError("Response status code is 403", 403)
        else:
            logger.error(f"HTTP error {res.status_code} for endpoint {res.url}")
            data = {}
        return data 



def ingest_data(
    sql_table_name_raw: str,
    flight_data: dict,
    db_config_filepath: PosixPath | None = None
) -> None:
    """Ingest data into Postgres database

    Args:
        db_config_filepath (PosixPath | None): absolute path to the db config file (deprecated)
        sql_table_name_raw (str): SQL table name where raw data are stored
        data (dict): a generator returning data as a dictionary
    """
    # Database connection
    conn, cur = utils.connect_db()
    i = 0
    e = 0
    for data in get_flights_generator(flight_data):
        raw_data = {"data": Json(data)}  # Create a dictionary with a key 'data' that is the column name in postgres raw table
        try:
            utils.insert_data_into_db(cur, sql_table_name_raw, raw_data)
        except (Exception, psycopg2.Error) as e:
            logger.exception(e)
            conn.rollback()
            e += 1
        else:
            conn.commit()
            i += 1
    conn.close()
    logger.info(f"{i} rows were added into the database raw table.")
    logger.warning(f"{e} rows couldn't be added because Exceptions.")
    logger.info("Connection closed to the database")


def get_flights_generator(data: str) -> Generator[dict, None, None]:
    data_flight = data["FlightInformation"]["Flights"]["Flight"]
    if isinstance(data_flight, dict):
        data_flight = (data_flight,)
    for elem in data_flight:
        yield elem


def run_customer_flight_information_pipeline(generic_endpoint_url: str, date_time: str, airport_iata: str, table_name: str) -> None:
    try:
        token, expiration_time = get_token()
    except ValueError as e:
        print(e)
        raise TokenException("Coudln't get the Token")
    else:
        session = (requests.Session())
        retries = Retry(
            total=3,
            backoff_factor=0,
            allowed_methods=["GET"],
            status_forcelist=[404, 429, 500, 502, 503, 504],
            raise_on_status=False,
        )
        session.mount("https://", HTTPAdapter(max_retries=retries))
        try:
            url = generic_endpoint_url.format(airport_iata, date_time)
            data = customer_flight_information_airport(session, url, token)
        except ValueError as e:
            logging.error(e)
            if e.args[1] == 403:
                raise EndPointException("Max Limit Requests Reached")
            else:
                raise EndPointException("Endpoint not reachable.")
        else:
            if data:
                db_config_filepath = None  # Set to None to maintain compatibility (deprecated)
                ingest_data(table_name, data, db_config_filepath)

