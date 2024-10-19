#!/usr/bin/env python
import os
import time
import datetime
import json
import logging

from dotenv import load_dotenv
import pika

from flight_schedules_pipeline import load_flight_schedules

logger = logging.getLogger(__name__)

load_dotenv()
RABBITMQ_HOST = os.environ['RABBITMQ_HOST']
RABBITMQ_PORT = os.environ['RABBITMQ_PORT']
FLIGHT_SCHEDULES_CHANNEL=os.environ['FLIGHT_SCHEDULES_CHANNEL']
LOG_FILE_PATH = os.environ['LOG_FILE_PATH']

def main():
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host=RABBITMQ_HOST, port=RABBITMQ_PORT))
    channel = connection.channel()

    channel.queue_declare(queue=FLIGHT_SCHEDULES_CHANNEL, durable=True)
    logger.info(' [*] Waiting for messages. To exit press CTRL+C')


    def callback(ch, method, properties, body):
        message = body.decode()
        logger.info(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}: [x] Received {message}")
        message = json.loads(message)
        try:
            load_flight_schedules(message['origin'], message['destination'], message['date'])
        except ValueError as e:
            if e.args[-1] == 403:
                logger.warning("ERROR: RATE LIMIT REACHED, WE SHOULD SLEEP A BIT ...")
                logger.warning(e)
                ch.basic_reject(delivery_tag=method.delivery_tag)
                logger.warning(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}: Sleeping for 30 minutes  ZZZZZZZZZZZZZ")
                time.sleep(30*60)  # Sleep during 30 minutes before restarting again
        except Exception as e:
            logger.error("ERROR: UNEXPECTED ERROR, producer will not acknowledge and it will hung. Resolve manually.")
            logger.error(e)
            ch.basic_reject(delivery_tag=method.delivery_tag)
        else:
            logger.info(" [x] Done")
            ch.basic_ack(delivery_tag=method.delivery_tag)
            
    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue=FLIGHT_SCHEDULES_CHANNEL, on_message_callback=callback)
    channel.start_consuming()
    

if __name__ == "__main__":
    logFormatter = logging.Formatter("%(asctime)s [%(levelname)-5.5s]  %(message)s")
    fileHandler = logging.FileHandler(f"{LOG_FILE_PATH}/consumer.log")
    fileHandler.setFormatter(logFormatter)
    logger.addHandler(fileHandler)
    consoleHandler = logging.StreamHandler()
    consoleHandler.setFormatter(logFormatter)
    logger.addHandler(consoleHandler)
    logger.setLevel(logging.INFO)
    
    main()
    