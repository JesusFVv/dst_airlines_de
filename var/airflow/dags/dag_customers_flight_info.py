from airflow.decorators import dag
from airflow.providers.ssh.operators.ssh import SSHOperator
from pendulum import datetime

@dag(start_date=datetime(2024, 10, 20, tz="UTC"), schedule="20 2 * * *", catchup=False, tags=["dst_project", "customer_flight_info"])
def customer_flight_info_ssh_operator():
    customer_flight_info_producer = SSHOperator(
        task_id="customer_flight_info_producer",
        ssh_conn_id='WSL_Home',
        command='docker container start customer_flight_info_producer'
    )
    
    customer_flight_info_producer

customer_flight_info_ssh_operator()