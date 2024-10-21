import sys
import os
import getpass
import logging
from pathlib import Path
from utils import connect_db

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def execute_sql_script(sql_script, db_config_path=None):
    if not os.path.isfile(sql_script):
        logger.error(f"SQL script {sql_script} does not exist.")
        sys.exit(1)

    try:
        conn, cursor = connect_db(db_config_path)
    except Exception as e:
        logger.error(f"Fail to connect to the database: {e}")
        sys.exit(1)

    try:
        with open(sql_script, 'r') as file:
            sql = file.read()
            cursor.execute(sql)
            conn.commit()
            logger.info(f"SQL script {sql_script} executed successfully.")
    except Exception as e:
        logger.error(f"An error occured executing SQL script: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

def main():
    if len(sys.argv) == 3:
        sql_script = sys.argv[1]
        db_config_path = Path(sys.argv[2])
    elif len(sys.argv) == 2:
        sql_script = sys.argv[1]
        db_config_path = None
    else:
        logger.error(f"Usage: {sys.argv[0]} <SQL_SCRIPT> <DB_CONFIG_PATH>")
        sys.exit(1)

    execute_sql_script(sql_script, db_config_path)

    

if __name__ == "__main__":
    main()
