# Pull base image
FROM python:3.11-alpine3.20

# Set working directory
WORKDIR /usr/src/app/

# Copy file
COPY requirements.txt .

# Install Python packages
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy folder and files
COPY common ./common
COPY load_l2_customer_flight_info.py .

# Define environment variables
ENV POSTGRES_DBUSER_FILE=/usr/src/app/etc/postgres_user.txt
ENV POSTGRES_DBUSER_PASSWORD_FILE=/usr/src/app/etc/postgres_password.txt

# Define volume
VOLUME /usr/src/app/etc

# Run command
CMD [ "python3", "stats_l3_customer_flight_info.py" ]
