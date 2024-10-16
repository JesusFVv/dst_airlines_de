#!/usr/bin/env python
import os
import time
import json

from dotenv import load_dotenv
import pika

from lufthansa_api_pipeline import load_flight_schedules


load_dotenv()
RABBITMQ_HOST = os.environ['RABBITMQ_HOST']
RABBITMQ_PORT = os.environ['RABBITMQ_PORT']
FLIGHT_SCHEDULES_CHANNEL=os.environ['FLIGHT_SCHEDULES_CHANNEL']

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host=RABBITMQ_HOST, port=RABBITMQ_PORT))
channel = connection.channel()

channel.queue_declare(queue=FLIGHT_SCHEDULES_CHANNEL, durable=True)
print(' [*] Waiting for messages. To exit press CTRL+C')


def callback(ch, method, properties, body):
    message = body.decode()
    print(f" [x] Received {message}")
    message = json.loads(message)
    load_flight_schedules(message['origin'], message['destination'], message['date'])
    print(" [x] Done")
    ch.basic_ack(delivery_tag=method.delivery_tag)


channel.basic_qos(prefetch_count=1)
channel.basic_consume(queue=FLIGHT_SCHEDULES_CHANNEL, on_message_callback=callback)

channel.start_consuming()