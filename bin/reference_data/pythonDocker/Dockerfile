FROM python:3.11-alpine3.20
WORKDIR /app
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
COPY ./ingestRefData_01_referenceDataRaw.sql ./reference_data/
COPY ./runSqlScript.py ./common/
COPY ./utils.py ./common/
COPY ./database.ini ./common/
CMD [ "python3", "./common/runSqlScript.py", "./reference_data/ingestRefData_01_referenceDataRaw.sql", "./common/database.ini" ]
