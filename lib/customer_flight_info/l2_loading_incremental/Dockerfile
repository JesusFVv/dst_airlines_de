FROM python:3.11-alpine3.20

WORKDIR /usr/src/app/
RUN mkdir -p log etc

COPY customer_flight_info/l2_loading_incremental/requirements.txt ./

RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

COPY ./common ./common
COPY customer_flight_info/l2_loading_incremental/l2_incremental_loading.py ./

ENV POSTGRES_DBUSER_FILE=/usr/src/app/etc/postgres_user.txt
ENV POSTGRES_DBUSER_PASSWORD_FILE=/usr/src/app/etc/postgres_password.txt
ENV LOG_FILE_PATH=/usr/src/app/log

VOLUME /usr/src/app/log
VOLUME /usr/src/app/etc

CMD [ "python3", "l2_incremental_loading.py" ]
