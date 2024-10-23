# Pull base image
FROM python:3.11-alpine3.20

# Set working directory
WORKDIR /usr/src/app/

# Add packages that are needed to install py7zr Python library
RUN apk add gcc python3-dev musl-dev linux-headers

# Copy file
COPY requirements.txt .

# Install Python packages
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy folder and files
COPY common ./common
COPY load_l1_customer_flight_info.py .

# Define environment variables
ENV DATA_FOLDER=/usr/src/app/data/customerFlightInfo
ENV POSTGRES_DBUSER_FILE=/usr/src/app/etc/postgres_user.txt
ENV POSTGRES_DBUSER_PASSWORD_FILE=/usr/src/app/etc/postgres_password.txt

# Define volumes
VOLUME /usr/src/app/data/customerFlightInfo
VOLUME /usr/src/app/etc

# Run command
CMD [ "python3", "load_l1_customer_flight_info.py" ]
