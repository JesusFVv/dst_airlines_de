#!/usr/bin/env python
import os
from typing import List, Iterator, Any
import itertools
import datetime
import json
import logging

from dotenv import load_dotenv
import pika
import pika.adapters.blocking_connection

logger = logging.getLogger(__name__)

load_dotenv()
RABBITMQ_HOST = os.environ['RABBITMQ_HOST']
RABBITMQ_PORT = os.environ['RABBITMQ_PORT']
FLIGHT_SCHEDULES_CHANNEL=os.environ['FLIGHT_SCHEDULES_CHANNEL']
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
    


def get_flight_routes() -> Iterator[str]:
    """Get all the routes (origin, destination) for the list of airports

    Yields:
        Iterator[str, str]: _description_
    """
    airports: List[str] = load_airports_icao()
    for origin, destination in itertools.product(airports, airports):
        if origin == destination:
                continue
        else:
            yield (origin, destination)


def get_flight_date() -> Iterator[str]:
    """Return the dates from (today + 1 day) to (today + NumDays) in iso format

    Returns:
        str: _description_
    """
    initial_offset_in_days = 90
    numdays = 1
    date_base = datetime.date.today() + datetime.timedelta(days=initial_offset_in_days)
    for x in range(1, numdays + 1):
        yield (date_base + datetime.timedelta(days=x)).isoformat()


def get_flight_dates_for_backlog() -> Iterator[str]:
    """Return the dates from (today + 1 day) to (today + NumDays) in iso format

    Returns:
        str: _description_
    """
    initial_offset_in_days = 30
    numdays = 60
    date_base = datetime.date.today() + datetime.timedelta(days=initial_offset_in_days)
    for x in range(1, numdays + 1):
        yield (date_base + datetime.timedelta(days=x)).isoformat()

def create_message(date: str, flight_route: List[str]) -> str:
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
    message['origin'] = flight_route[0]
    message['destination'] = flight_route[1]
    
    return json.dumps(message)


def publish_messages(channel: pika.adapters.blocking_connection.BlockingChannel) -> None:
    for date in get_flight_date():
        for flight_route in get_flight_routes():
            message = create_message(date, flight_route)
            channel.basic_publish(
                exchange='',
                routing_key=FLIGHT_SCHEDULES_CHANNEL,
                body=message,
                properties=pika.BasicProperties(
                    delivery_mode=pika.DeliveryMode.Persistent
                ))
            logger.info(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}: [x] Sent {message}")
    

def main() -> None:
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host=RABBITMQ_HOST, port=RABBITMQ_PORT))
    channel = connection.channel()
    channel.queue_declare(queue=FLIGHT_SCHEDULES_CHANNEL, durable=True)
    publish_messages(channel)
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
    