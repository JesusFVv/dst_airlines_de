import os
from urllib.request import BaseHandler
from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator
from airflow.providers.docker.operators.docker import DockerOperator
from airflow.providers.ssh.operators.ssh import SSHOperator
from docker.types import Mount
from pendulum import datetime

PROJECT_ABSOLUT_PATH = os.environ['PROJECT_ABSOLUT_PATH']  # Import the env variable from Host: NOT IDEAL!!!!!

# Next is the DAG to launch DockerContainers with the DockerOperator, it only works if permissions of /var/run/docker.sock are 666
@dag(start_date=datetime(2024, 10, 20, tz="UTC"), schedule=None, catchup=False, tags=["dst_project", "flight_schedules"])
def flight_schedules_launch_producer_docker_operator():

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
        },
        mounts=[
            Mount(source='/home/ubuntu-user1/prj/dst_airlines_project/dst_airlines_de/data/airports/airports.csv', target='/usr/src/app/data/airports.csv', type="bind"),
            Mount(source='/home/ubuntu-user1/prj/dst_airlines_project/dst_airlines_de/var/flight_schedules/log/producer', target='/usr/src/app/log', type="bind"),
        ]        
    )
      
    flight_schedules_producer

flight_schedules_launch_producer_docker_operator()


@dag(start_date=datetime(2024, 10, 20, tz="UTC"), schedule="10 2 * * *", catchup=False, tags=["dst_project", "flight_schedules"])
def flight_schedules_launch_producer_ssh_operator():
    flight_schedules_producer = SSHOperator(
        task_id="flight_schedules_producer",
        ssh_conn_id='WSL_Home',
        command=f"pushd {PROJECT_ABSOLUT_PATH} && bash lib/flights_scheduled/producer/launch_producer.sh "
    )
    
    flight_schedules_producer

flight_schedules_launch_producer_ssh_operator()



@dag(start_date=datetime(2024, 10, 20, tz="UTC"), schedule=None, catchup=False, tags=["dst_project", "flight_schedules"])
def flight_schedules_backlog_producer_ssh_operator():
    flight_schedules_producer_backlog = SSHOperator(
        task_id="flight_schedules_producer_backlog",
        ssh_conn_id='WSL_Home',
        command=f"pushd {PROJECT_ABSOLUT_PATH} && bash lib/flights_scheduled/producer/launch_producer_backlog.sh "
    )
    
    flight_schedules_producer_backlog

flight_schedules_backlog_producer_ssh_operator()