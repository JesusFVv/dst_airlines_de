# Customer flight information airport
This script aims at collecting data from [Lufthansa Open API](https://developer.lufthansa.com/docs) for two endpoints:
- Customer flight information at departure airport
- Customer flight information at arrival airport

The data collect is performed through a Python script that is embedded into a Docker container.

## Docker
In the Datascientest VM, the Docker version is 20.10.3.\
To run the container, there are two mandatory steps to follow:
- Build Docker image
- Run the container

### Build image
Make sure to be in the directory where the Dockerfile stands.
```sh
cd /home/ubuntu/dst_airlines_de/bin/customer_flight_info  #Folder where the Dockerfile stands
docker build -t python_customer_flight_info .
```

### Run container
```sh
docker run -d \
--volume $(pwd)/customer_flight_info_data:/app/output \
--name python_app \
python_customer_flight_info
```

### Logs
```sh
docker logs python_app
```

### Remove container
```sh
docker container rm python_app
```

### Remove images
```sh
docker image rm python_customer_flight_info:latest python:3.11-alpine3.20
```
