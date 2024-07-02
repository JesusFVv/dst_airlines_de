FROM python:3.11-alpine3.20
WORKDIR /app
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
COPY input ./input
COPY customer_flight_info_at_airport.py .
CMD [ "python3", "customer_flight_info_at_airport.py" ]
