# Docker

## Build image
cd /home/ubuntu/DST_airlines/lufthansa
docker build -t python_customer_flight_info .

## Run container
docker run -d \
--volume $(pwd)/customer_flight_info_data:/app/output \
--name python_app \
python_customer_flight_info

## Remove images
docker image rm python_customer_flight_info:latest python:3.11-alpine3.20
