import os
from airflow.decorators import dag
from airflow.contrib.hooks.ssh_hook import SSHHook
from airflow.providers.ssh.operators.ssh import SSHOperator
from pendulum import datetime

PROJECT_ABSOLUT_PATH = os.environ['PROJECT_ABSOLUT_PATH']  # Import the env variable from Host: NOT IDEAL!!!!!
ssh_hook = SSHHook(ssh_conn_id="WSL_Home", cmd_timeout=None, conn_timeout=100)

@dag(start_date=datetime(2024, 11, 10, tz="UTC"), schedule="0 * * * *", catchup=False, tags=["dst_project", "scheduled_routes"])
def scheduled_routes_dump_to_graphdb_ssh_operator():
    scheduled_routes_dump_to_graphdb = SSHOperator(
        task_id="scheduled_routes_dump_to_graphdb",
        ssh_hook=ssh_hook,
        command=f"pushd {PROJECT_ABSOLUT_PATH} && bash lib/db_dump/l3_scheduled_routes_dump/l3_scheduled_routes_dump.sh "
    )
    
    scheduled_routes_dump_to_graphdb

scheduled_routes_dump_to_graphdb_ssh_operator()
