FROM python:3.11-alpine3.20

WORKDIR /usr/src/app

RUN pip install --no-cache-dir python-dotenv pika "dlt[postgres]"
COPY consumer.py flight_schedules_pipeline.py ./
COPY .dlt/config.toml .dlt/secrets.toml ./.dlt/
RUN mkdir log
VOLUME /usr/src/app/.dlt/secrets.toml
VOLUME /usr/src/app/log

CMD [ "python3", "consumer.py" ]
