# Pull base image
FROM python:3.11-alpine3.20

# Set some variables
ARG code_folder=/home/ubuntu/dst_airlines_de/bin/reference_data/full_ingest/
ARG postgres_folder=/home/ubuntu/dst_airlines_de/src/project_deployment_postgres/

# Set working directory
WORKDIR $code_folder

# Add packages that are needed to install py7zr Python library
RUN apk add gcc python3-dev musl-dev linux-headers bash

# Copy files
COPY postgres_user.txt postgres_password.txt docker-compose.yml $postgres_folder
COPY requirements.txt .

# Install Python packages
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy folder and files
COPY common ./common
COPY reference_data/*.sh ./
COPY reference_data/*.py ./
COPY reference_data/*.sql ./
COPY reference_data/*.md ./

# Define default shell
SHELL ["/bin/bash", "-c"]

# Run command
CMD [ "/bin/bash", "./ingestRefData_raw.sh" ]
