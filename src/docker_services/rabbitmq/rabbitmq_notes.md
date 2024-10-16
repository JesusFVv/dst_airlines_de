# RabbitMQ

https://www.rabbitmq.com/


## Installation
### Docker Container

The most simple installation from [DockerHub](https://hub.docker.com/_/rabbitmq/).

```bash
set -a
source .env
set +a

CONTAINER_NAME=rabbitmq
docker container stop ${CONTAINER_NAME} >& /dev/null
docker container rm ${CONTAINER_NAME} >& /dev/null
docker run -d --name $CONTAINER_NAME \
    -v ${PROJECT_ABSOLUT_PATH}/var/rabbitmq/data:/var/lib/rabbitmq \
    --network dst-network \
    --hostname my-rabbit \
    --restart unless-stopped \
    rabbitmq:3
```

## RabbitMQ commands

- List queues and messages
```bash
sudo rabbitmqctl list_queues

Timeout: 60.0 seconds ...
Listing queues for vhost / ...
name    messages
hello   0
```
- Get the queues, messages and unacknowledged messages
```bash
sudo rabbitmqctl list_queues name messages_ready messages_unacknowledged

Timeout: 60.0 seconds ...
Listing queues for vhost / ...
name    messages_ready  messages_unacknowledged
hello   0       0
```

- List exchanges

```bash
sudo rabbitmqctl list_exchanges

Listing exchanges for vhost / ...
name    type
amq.headers     headers
amq.match       headers
        direct
amq.rabbitmq.trace      topic
amq.fanout      fanout
amq.topic       topic
amq.direct      direct
```

- List Bindings

```bash
sudo rabbitmqctl list_bindings
```

## Work Queue components

- [Standard queue](https://www.rabbitmq.com/tutorials/tutorial-one-python)
- [Work queue](https://www.rabbitmq.com/tutorials/tutorial-two-python)

### Sender

It's the producer of the information sent to the exchange and integrated to the queue.

Steps:

- Create a connection and declare a queue.
    
    If we need to persist the queue in disk use `durable=True` when declaring the queue.

```python
import pika
connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='localhost'))
channel = connection.channel()
channel.queue_declare(queue='task_queue', durable=True)
```

- Send a message to the exchange (empty exchange) and the queue.

    The message is sent first to an exchange, and then to the queue.

    In order to persist the messages in disk we declare `properties=pika.BasicProperties(delivery_mode=pika.DeliveryMode.Persistent)`.

```python
message = "Hello World!"
channel.basic_publish(
    exchange='',
    routing_key='task_queue',
    body=message,
    properties=pika.BasicProperties(
        delivery_mode=pika.DeliveryMode.Persistent
    ))
print(f" [x] Sent {message}")
```

- Close connection

    The Sender will close connection and exit once the message has been delivered.

```python
connection.close()
```

### Receiver (or Worker)

- Create a connection and declare a queue. The queue is declared by the Sender and the Receiver, but only created once (`queue_declare` is idempotent)

```python
import pika

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='localhost'))
channel = connection.channel()
channel.queue_declare(queue='task_queue', durable=True)
print(' [*] Waiting for messages. To exit press CTRL+C')
```

- Function called for each message received. It will process te message.

```python
def callback(ch, method, properties, body):
    print(f" [x] Received {body}")
    # Do some staff
    # Manually ACKNOWLEDGE the message if function returns OK
```

- Receive messages and apply callback function. The Receiver will run continuously.

    The message can be acknowledge manually (ex. only if callback function return is OK) or automatically (ex. just set `auto_ack=True` to acknowledge when the message is received, no matters if the callback function returns an error)

```python
channel.basic_qos(prefetch_count=1)
channel.basic_consume(queue='task_queue', on_message_callback=callback, auto_ack=True)
channel.start_consuming()
```

- Adding the 'Fair Dispatch' propertie (`channel.basic_qos(prefetch_count=1)`) prevents RabbitMQ sending multiple messages to a receiver that has not acknowledge yet its last message. This is usefull if we want to ensure that all messages are processed, and that load repartition is even between multiple receivers. (Default acknowledge time is 30 minutes)


