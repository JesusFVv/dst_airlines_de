FROM python:3.11-alpine3.20

WORKDIR /usr/src/app

RUN pip install --no-cache-dir python-dotenv pika "dlt[postgres]"
COPY consumer.py flight_schedules_pipeline.py ./
COPY .dlt/config.toml .dlt/secrets.toml ./.dlt/

CMD [ "python3", "consumer.py" ]
