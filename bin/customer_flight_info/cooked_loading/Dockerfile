# Pull base image
FROM python:3.11-alpine3.20

# Set some variables
ARG code_folder=/home/ubuntu/dst_airlines_de/bin/customer_flight_info/cooked_loading/
ARG postgres_folder=/home/ubuntu/dst_airlines_de/src/project_deployment_postgres/

# Set working directory
WORKDIR $code_folder

# Copy files
COPY postgres_user.txt postgres_password.txt docker-compose.yml $postgres_folder
COPY requirements.txt .

# Install Python packages
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy folder and files
COPY common ./common
COPY load_customer_flight_info_cooked.py .

# Run command
CMD [ "python3", "load_customer_flight_info_cooked.py" ]
