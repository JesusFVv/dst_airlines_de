FROM python:3.11-alpine3.20
WORKDIR /app
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
COPY input ./input
COPY extract_customer_flight_info.py .
CMD [ "python3", "extract_customer_flight_info.py" ]
