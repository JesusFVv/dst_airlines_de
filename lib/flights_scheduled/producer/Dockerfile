FROM python:3.11-alpine3.20

WORKDIR /usr/src/app

COPY producer.py ./
RUN pip install --no-cache-dir python-dotenv pika
RUN mkdir data log
RUN touch data/airports.csv
VOLUME /usr/src/app/data
VOLUME /usr/src/app/log

CMD [ "python3", "producer.py" ]
