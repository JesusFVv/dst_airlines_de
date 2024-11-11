import os
from airflow.decorators import dag
from airflow.providers.ssh.operators.ssh import SSHOperator
from pendulum import datetime

PROJECT_ABSOLUT_PATH = os.environ['PROJECT_ABSOLUT_PATH']  # Import the env variable from Host: NOT IDEAL!!!!!

@dag(start_date=datetime(2024, 11, 10, tz="UTC"), schedule="0 9 * * *", catchup=False, tags=["dst_project", "dump_db"])
def dst_airlines_db_dump_ssh_operator():
    dst_airlines_db_dump = SSHOperator(
        task_id="dst_airlines_db_dump",
        ssh_conn_id='WSL_Home',
        command=f"pushd {PROJECT_ABSOLUT_PATH} && bash lib/db_dump/dst_dump/dst_airlines_db_dump.sh "
    )
    
    dst_airlines_db_dump

dst_airlines_db_dump_ssh_operator()

@dag(start_date=datetime(2024, 11, 10, tz="UTC"), schedule="30 9 * * *", catchup=False, tags=["dst_project", "dump_db"])
def dst_graph_db_dump_ssh_operator():
    dst_graph_db_dump = SSHOperator(
        task_id="dst_graph_db_dump",
        ssh_conn_id='WSL_Home',
        command=f"pushd {PROJECT_ABSOLUT_PATH} && bash lib/db_dump/dst_dump/dst_graph_db_dump.sh "
    )
    
    dst_graph_db_dump

dst_graph_db_dump_ssh_operator()


