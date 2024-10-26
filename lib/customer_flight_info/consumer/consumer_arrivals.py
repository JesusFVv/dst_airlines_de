#!/usr/bin/env python
"""
Consumer that does two things:
- Extraction customer flight data from arrivals endpoint
- And inserting new data to the DB
"""
# Only for test
import sys
sys.path.append("/home/ubuntu-user1/prj/dst_airlines_project/dst_airlines_de/lib")
#
import os
import time
import json
import logging

from dotenv import load_dotenv
import pika

from customer_flight_info_pipeline import (
    run_customer_flight_information_pipeline,
    TokenException,
    EndPointException,
    CUSTOMER_FLIGHT_INFO_ARRIVAL_AIRPORT_ENDPOINT,
)

logger = logging.getLogger(__name__)
logger_pipeline = logging.getLogger('customer_flight_info_pipeline')

load_dotenv()
RABBITMQ_HOST = os.environ['RABBITMQ_HOST']
RABBITMQ_PORT = os.environ['RABBITMQ_PORT']
CHANNEL_NAME=os.environ['CUSTOMERS_FLIGHT_INFO_ARRIVALS_CHANNEL']
LOG_FILE_PATH = os.environ['LOG_FILE_PATH']
AIRPORTS_FILE_PATH = os.environ['AIRPORTS_FILE_PATH']
CUSTOMER_FLIGHT_INFO_TABLE_NAME = os.environ['CUSTOMER_FLIGHT_INFO_TABLE_NAME']


def main():
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host=RABBITMQ_HOST, port=RABBITMQ_PORT))
    channel = connection.channel()
    channel.queue_declare(queue=CHANNEL_NAME, durable=True)
    logger.info(' [*] Waiting for messages. To exit press CTRL+C')
    def callback(ch, method, properties, body):
        message = body.decode()
        logger.info(f"[x] Received {message}")
        message = json.loads(message)
        try:
            run_customer_flight_information_pipeline(CUSTOMER_FLIGHT_INFO_ARRIVAL_AIRPORT_ENDPOINT, message['date'], message['airport_iata'], CUSTOMER_FLIGHT_INFO_TABLE_NAME)
        except (TokenException, EndPointException) as e:
            logger.warning(e)
            ch.basic_reject(delivery_tag=method.delivery_tag)
            logger.warning("Sleeping for 30 minutes  ZZZZZZZZZZZZZ")
            time.sleep(30*60)  # Sleep during 30 minutes before restarting again
        except Exception as e:
            logger.error("ERROR: UNEXPECTED ERROR, producer will not acknowledge and it will hung. Resolve manually.")
            logger.error(e)
            ch.basic_reject(delivery_tag=method.delivery_tag)
        else:
            logger.info("[x] Done")
            ch.basic_ack(delivery_tag=method.delivery_tag)
    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue=CHANNEL_NAME, on_message_callback=callback)
    channel.start_consuming()
    

if __name__ == "__main__":
    logFormatter = logging.Formatter("%(asctime)s [%(levelname)-5.5s] %(name)s: ARRIVALS %(message)s")
    fileHandler = logging.FileHandler(f"{LOG_FILE_PATH}/consumer_arrivals.log")
    fileHandler.setFormatter(logFormatter)
    logger.addHandler(fileHandler)
    logger_pipeline.addHandler(fileHandler)
    consoleHandler = logging.StreamHandler()
    consoleHandler.setFormatter(logFormatter)
    logger.addHandler(consoleHandler)
    logger_pipeline.addHandler(consoleHandler)
    logger.setLevel(logging.INFO)
    logger_pipeline.setLevel(logging.INFO)
    
    main()
    