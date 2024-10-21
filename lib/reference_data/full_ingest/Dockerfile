# Pull base image
FROM python:3.11-alpine3.20

# Set working directory
WORKDIR /usr/src/app

# Add packages that are needed to install py7zr Python library
RUN apk add gcc python3-dev musl-dev linux-headers bash
RUN mkdir -p common etc data/referenceData

# Copy files
COPY requirements.txt .
# Install Python packages
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
# Copy folder and files
COPY common ./common
COPY reference_data/ingestRefData_00_initConfigure.sh reference_data/ingestRefData_raw.sh ./
COPY reference_data/ingestRefData_02_ingestReferenceDataRaw.py ./
COPY reference_data/ingestRefData_01_referenceDataRaw.sql reference_data/ingestRefData_03_referenceDataCooked.sql ./

ENV DATA_FOLDER=/usr/src/app/data/referenceData
ENV POSTGRES_DBUSER_FILE=/usr/src/app/etc/postgres_user.txt
ENV POSTGRES_DBUSER_PASSWORD_FILE=/usr/src/app/etc/postgres_password.txt

VOLUME /usr/src/app/data/referenceData
VOLUME /usr/src/app/etc
# Define default shell
SHELL ["/bin/bash", "-c"]

# Run command
CMD [ "/bin/bash", "./ingestRefData_raw.sh" ]

