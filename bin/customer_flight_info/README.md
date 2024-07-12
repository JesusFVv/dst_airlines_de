# Customer flight information airport
The process to extract, transform and load data from customer flight information airport endpoints is composed of 4 steps:
1. Extract data
2. Load raw data
3. Transform data
4. Load cooked data

## Extract data
Data extraction is performed daily by the Python script **extract_customer_flight_info.py** that is embedded into a Docker container.\
It aims at collecting data from [Lufthansa Open API](https://developer.lufthansa.com/docs) for two endpoints:
- [Customer flight information at departure airport](https://developer.lufthansa.com/docs/read/api_details/operations/Customer_Flight_Information_at_Departure_Airport)
- [Customer flight information at arrival airport](https://developer.lufthansa.com/docs/read/api_details/operations/Customer_Flight_Information_at_Arrival_Airport)

### Docker
In the Datascientest VM, the Docker version is 20.10.3.\
To run the container, there are two mandatory steps to follow:
- Build Docker image
- Run the container

#### Build image
Make sure to be in the directory where the Dockerfile stands.
```sh
cd /home/ubuntu/dst_airlines_de/bin/customer_flight_info  # Folder where the Dockerfile stands
docker build -t python_customer_flight_info .
```

#### Run container
```sh
docker run -d \
--volume $(pwd)/customer_flight_info_data:/app/output \
--name python_app \
python_customer_flight_info
```

#### Logs
To see the logs:
```sh
docker logs python_app
```

#### Remove container
In case of the container has to be restarted from scratch, it has to be removed before.
```sh
docker container rm python_app
```

#### Remove images
In case of the Docker images have to be rebuilt from scratch, they have to be removed before.
```sh
docker image rm python_customer_flight_info:latest python:3.11-alpine3.20
```

## Load raw data
**load_customer_flight_info_raw.py**

## Transform data
**transform_customer_flight_info.py**

## Load cooked data
**load_customer_flight_info_cooked.py**
