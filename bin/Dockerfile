FROM python:3.11-alpine3.20
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY input ./input
COPY customer_flight_info_at_airport_VM.py .
CMD [ "python3", "customer_flight_info_at_airport_VM.py" ]
