FROM python:3.11-alpine3.20
WORKDIR /app
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
COPY load_customer_flight_info_raw.py .
CMD [ "python3", "load_customer_flight_info_raw.py" ]
