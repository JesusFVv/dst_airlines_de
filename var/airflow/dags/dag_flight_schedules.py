from airflow.decorators import dag
from airflow.operators.bash import BashOperator
from airflow.providers.docker.operators.docker import DockerOperator
from docker.types import Mount
from pendulum import datetime


@dag(start_date=datetime(2024, 10, 19), schedule=None, catchup=False)
def airflow_docker_operator():

    flight_schedules_producer = DockerOperator(
        task_id='flight_schedules_producer',
        image='dst_flight_schedules_producer:latest',
        container_name='flight_schedules_producer',
        docker_url='unix://var/run/docker.sock',
        network_mode='dst_network',
        mount_tmp_dir=False,
        auto_remove='success',
        environment={
            'AIRPORTS_FILE_PATH': '/usr/src/app/data/airports.csv',
            'RABBITMQ_HOST': 'rabbitmq',
            'RABBITMQ_PORT': '5672',
            'FLIGHT_SCHEDULES_CHANNEL': 'flight_schedules',
            'LOG_FILE_PATH': '/usr/src/app/log',
            'PROJECT_ABSOLUT_PATH': '/home/ubuntu-user1/prj/dst_airlines_project/dst_airlines_de',
        },
        mounts=[
            Mount(source='/home/ubuntu-user1/prj/dst_airlines_project/dst_airlines_de/data/airports/airports.csv', target='/usr/src/app/data/airports.csv', type="bind"),
            Mount(source='/home/ubuntu-user1/prj/dst_airlines_project/dst_airlines_de/var/flight_schedules/log/producer', target='/usr/src/app/log', type="bind"),
        ]        
    )
      
    flight_schedules_producer


airflow_docker_operator()