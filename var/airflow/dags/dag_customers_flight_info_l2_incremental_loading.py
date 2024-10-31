import os
from airflow.decorators import dag
from airflow.providers.ssh.operators.ssh import SSHOperator
from pendulum import datetime

PROJECT_ABSOLUT_PATH = os.environ['PROJECT_ABSOLUT_PATH']  # Import the env variable from Host: NOT IDEAL!!!!!

@dag(start_date=datetime(2024, 10, 20, tz="UTC"), schedule="0 * * * *", catchup=False, tags=["dst_project", "customer_flight_info"])
def customer_flight_info_l2_incremental_loading_ssh_operator():
    customer_flight_info_l2_incremental_loading = SSHOperator(
        task_id="customer_flight_info_l2_incremental_loading",
        ssh_conn_id='WSL_Home',
        command=f"pushd {PROJECT_ABSOLUT_PATH} && bash lib/customer_flight_info/l2_loading_incremental/launch_docker_container.sh "
    )
    
    customer_flight_info_l2_incremental_loading

customer_flight_info_l2_incremental_loading_ssh_operator()