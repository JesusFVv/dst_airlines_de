FROM python:3.11-alpine3.20

WORKDIR /usr/src/app
RUN mkdir -p data log etc
RUN touch data/airports.csv

COPY customer_flight_info/consumer/requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt
COPY customer_flight_info/consumer/consumer_departures.py customer_flight_info/consumer/customer_flight_info_pipeline.py ./
COPY ./common ./common

ENV POSTGRES_DBUSER_FILE=/usr/src/app/etc/postgres_user.txt
ENV POSTGRES_DBUSER_PASSWORD_FILE=/usr/src/app/etc/postgres_password.txt

VOLUME /usr/src/app/log
VOLUME /usr/src/app/secrets.toml
VOLUME /usr/src/app/etc
VOLUME /usr/src/app/data

CMD [ "python3", "consumer_departures.py" ]
