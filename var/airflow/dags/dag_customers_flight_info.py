import os
from airflow.decorators import dag
from airflow.providers.ssh.operators.ssh import SSHOperator
from airflow.operators.bash import BashOperator
from pendulum import datetime

PROJECT_ABSOLUT_PATH = os.environ['PROJECT_ABSOLUT_PATH']  # Import the env variable from Host: NOT IDEAL!!!!!

@dag(start_date=datetime(2024, 10, 20, tz="UTC"), schedule="20 2 * * *", catchup=False, tags=["dst_project", "customer_flight_info"])
def customer_flight_info_launch_producer_ssh_operator():
    customer_flight_info_producer = SSHOperator(
        task_id="customer_flight_info_producer",
        ssh_conn_id='WSL_Home',
        command=f"pushd {PROJECT_ABSOLUT_PATH} && bash lib/customer_flight_info/producer/launch_producer.sh "
    )
    
    flight_schedules_consumer_partial_stop_1 = SSHOperator(
        task_id="flight_schedules_consumer_partial_stop_1",
        cmd_timeout=60,
        ssh_conn_id='WSL_Home',
        command=f"docker container stop dst_docker_services-flight_schedules_consumer_b-1 "
    )
    
    flight_schedules_consumer_partial_stop_2 = SSHOperator(
        task_id="flight_schedules_consumer_partial_stop_2",
        cmd_timeout=60,
        ssh_conn_id='WSL_Home',
        command=f"docker container stop dst_docker_services-flight_schedules_consumer_b-2 "
    )
        
    flight_schedules_consumer_partial_stop_1 >> flight_schedules_consumer_partial_stop_2 >> customer_flight_info_producer
    
customer_flight_info_launch_producer_ssh_operator()



@dag(start_date=datetime(2024, 10, 20, tz="UTC"), schedule="0 5 * * *", catchup=False, tags=["dst_project", "customer_flight_info"])
def flight_schedules_launch_consumer_ssh_operator():
    flight_schedules_consumer_partial_start_1 = SSHOperator(
        task_id="flight_schedules_consumer_partial_start_1",
        cmd_timeout=60,
        ssh_conn_id='WSL_Home',
        command=f"docker container start dst_docker_services-flight_schedules_consumer_b-1 "
    )
    
    flight_schedules_consumer_partial_start_2 = SSHOperator(
        task_id="flight_schedules_consumer_partial_start_2",
        cmd_timeout=60,
        ssh_conn_id='WSL_Home',
        command=f"docker container start dst_docker_services-flight_schedules_consumer_b-2 "
    )
        
    flight_schedules_consumer_partial_start_1 >> flight_schedules_consumer_partial_start_2
    
flight_schedules_launch_consumer_ssh_operator()


