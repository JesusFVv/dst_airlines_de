import os
from airflow.decorators import dag
from airflow.providers.ssh.operators.ssh import SSHOperator
from pendulum import datetime

PROJECT_ABSOLUT_PATH = os.environ['PROJECT_ABSOLUT_PATH']  # Import the env variable from Host: NOT IDEAL!!!!!

@dag(start_date=datetime(2024, 10, 20, tz="UTC"), schedule="20 2 * * *", catchup=False, tags=["dst_project", "customer_flight_info"])
def customer_flight_info_ssh_operator():
    customer_flight_info_producer = SSHOperator(
        task_id="customer_flight_info_producer",
        ssh_conn_id='WSL_Home',
        command=f"pushd {PROJECT_ABSOLUT_PATH} && bash lib/customer_flight_info/producer/launch_producer.sh "
    )
    
    flight_schedules_consumer_partial_stop = SSHOperator(
        task_id="flight_schedules_consumer_partial_stop",
        ssh_conn_id='WSL_Home',
        command=f"docker container stop dst_docker_services-flight_schedules_consumer_b-1 && docker container stop dst_docker_services-flight_schedules_consumer_b-2 "
    )
    
    wait_until_end_of_customer_flight_information_consumer = SSHOperator(
        task_id="wait_until_end_of_customer_flight_information_consumer",
        ssh_conn_id='WSL_Home',
        command=f"sleep 120m"
    )
    
    flight_schedules_consumer_partial_start = SSHOperator(
        task_id="flight_schedules_consumer_partial_start",
        ssh_conn_id='WSL_Home',
        command=f"docker container start dst_docker_services-flight_schedules_consumer_b-1 && docker container start dst_docker_services-flight_schedules_consumer_b-2 "
    )
        
    flight_schedules_consumer_partial_stop >> customer_flight_info_producer >> wait_until_end_of_customer_flight_information_consumer >> flight_schedules_consumer_partial_start

customer_flight_info_ssh_operator()