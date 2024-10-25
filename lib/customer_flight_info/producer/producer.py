#!/usr/bin/env python
import os
from typing import List, Iterator, Sequence
import datetime
import json
import logging

from dotenv import load_dotenv
import pika
import pika.adapters.blocking_connection
import pandas as pd

logger = logging.getLogger(__name__)

load_dotenv()
RABBITMQ_HOST = os.environ['RABBITMQ_HOST']
RABBITMQ_PORT = os.environ['RABBITMQ_PORT']
CHANNELS_NAMES=(os.environ['CUSTOMERS_FLIGHT_INFO_ARRIVALS_CHANNEL'], os.environ['CUSTOMERS_FLIGHT_INFO_DEPARTURES_CHANNEL'])
AIRPORTS_FILE_PATH = os.environ['AIRPORTS_FILE_PATH']
LOG_FILE_PATH = os.environ['LOG_FILE_PATH']


def load_airports_icao() -> List[str]:
    """Load the list of the considered airports

    Returns:
        List[str]: _description_
    """
    airports_file_path = AIRPORTS_FILE_PATH
    with open(airports_file_path, "r", encoding="utf-8") as file:
        file.readline()
        airports = file.readlines()
    airports = list(map(lambda x: x.strip(), airports)) 
    return airports
    

def get_airports() -> Iterator[str]:
    """Get all the routes (origin, destination) for the list of airports

    Yields:
        Iterator[str, str]: _description_
    """
    airports: List[str] = load_airports_icao()
    for airport in airports:
        yield airport


def generate_datetime_array(
    start_date: str, stop_date: str, increment_value: str = "4h"
) -> Sequence[str]:
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


def get_flight_date() -> Iterator[str]:
    """Return the dates from (today + 1 day) to (today + NumDays) in iso format

    Returns:
        str: _description_
    """
    today_utc = datetime.datetime.now(datetime.timezone.utc).date()
    yesterday = today_utc - datetime.timedelta(days=1)
    two_am = datetime.time(hour=2, minute=0, second=0)
    yesterday_two_am = datetime.datetime.combine(yesterday, two_am).strftime(
        "%Y-%m-%d %H:%M:%S"
    )
    today = today_utc.strftime("%Y-%m-%d")
    datetime_array = generate_datetime_array(yesterday_two_am, today)
    for date_time in datetime_array:
        yield date_time


def create_message(date: str, airport_iata: str) -> str:
    """Create the message with the date and the flight route
    The message has a JSON format, with fields date, origin and destination.

    Args:
        date (str): _description_
        flight_route (List[str]): _description_

    Returns:
        str: _description_
    """
    message = {}
    message['date'] = date
    message['airport_iata'] = airport_iata
    
    return json.dumps(message)


def publish_messages(channel: pika.adapters.blocking_connection.BlockingChannel, channel_name: str) -> None:
    for date in get_flight_date():
        for airport_iata in get_airports():
            message = create_message(date, airport_iata)
            channel.basic_publish(
                exchange='',
                routing_key=channel_name,
                body=message,
                properties=pika.BasicProperties(
                    delivery_mode=pika.DeliveryMode.Persistent
                ))
            logger.info(f"[x] Sent to {channel_name} {message}")
    

def main() -> None:
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host=RABBITMQ_HOST, port=RABBITMQ_PORT))
    for channel_name in CHANNELS_NAMES:
        channel = connection.channel()
        channel.queue_declare(queue=channel_name, durable=True)
        publish_messages(channel, channel_name)
    connection.close()


if __name__ == "__main__":
    logFormatter = logging.Formatter("%(asctime)s [%(levelname)-5.5s]  %(message)s")
    fileHandler = logging.FileHandler(f"{LOG_FILE_PATH}/producer.log")
    fileHandler.setFormatter(logFormatter)
    logger.addHandler(fileHandler)
    consoleHandler = logging.StreamHandler()
    consoleHandler.setFormatter(logFormatter)
    logger.addHandler(consoleHandler)
    logger.setLevel(logging.INFO)
    
    main()
    