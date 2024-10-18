#!/usr/bin/env python
import os
import time
import datetime
import json

from dotenv import load_dotenv
import pika

from flight_schedules_pipeline import load_flight_schedules


load_dotenv()
RABBITMQ_HOST = os.environ['RABBITMQ_HOST']
RABBITMQ_PORT = os.environ['RABBITMQ_PORT']
FLIGHT_SCHEDULES_CHANNEL=os.environ['FLIGHT_SCHEDULES_CHANNEL']

def main():
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host=RABBITMQ_HOST, port=RABBITMQ_PORT))
    channel = connection.channel()

    channel.queue_declare(queue=FLIGHT_SCHEDULES_CHANNEL, durable=True)
    print(' [*] Waiting for messages. To exit press CTRL+C')


    def callback(ch, method, properties, body):
        message = body.decode()
        print(f" [x] Received {message}")
        message = json.loads(message)
        try:
            load_flight_schedules(message['origin'], message['destination'], message['date'])
        except ValueError as e:
            if e.args[-1] == 403:
                print(e)
                ch.basic_reject(delivery_tag=method.delivery_tag)
                connection.close()
        except Exception as e:
            print(e)
        else:
            print(" [x] Done")
            ch.basic_ack(delivery_tag=method.delivery_tag)
    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue=FLIGHT_SCHEDULES_CHANNEL, on_message_callback=callback)
    channel.start_consuming()
    

if __name__ == "__main__":
    while True:
        main()
        print(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}: Sleeping for 30 minutes  ZZZZZZZZZZZZZ")
        time.sleep(30*60)  # Sleep during 30 minutes before restarting again
    