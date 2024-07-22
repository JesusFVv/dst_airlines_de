FROM python:3.11-alpine3.20
WORKDIR /app
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
COPY ingestRefData_01_referenceDataRaw.sql .
CMD [ "python3", "../common/runSqlScript.py", "ingestRefData_01_referenceDataRaw.sql", "/home/ubuntu/dst_airlines_de/bin/customer_flight_info/database.ini" ]
