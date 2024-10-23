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
COPY input ./input
COPY extract_customer_flight_info.py .

# Define environment variable
ENV DATA_FOLDER=/usr/src/app/data/customerFlightInfo

# Define volume storing data
VOLUME /usr/src/app/data/customerFlightInfo

# Run command
CMD [ "python3", "extract_customer_flight_info.py" ]
