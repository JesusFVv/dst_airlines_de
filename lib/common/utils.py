from __future__ import annotations

from functools import total_ordering
import logging
from pathlib import Path, PosixPath
from typing import TYPE_CHECKING
import os

if TYPE_CHECKING:
    import psycopg2


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def get_filenames(files_path: PosixPath, suffix: str = "") -> list[PosixPath]:
    """Get a list of filenames. It is done recursively

    Args:
        files_path (PosixPath): absolute root path where the files are stored
        suffix (str): filter by the given suffix - it could be file extension or sth else

    Returns:
        files_list (list[PosixPath]): a list containing path of files
    """
    suffix = suffix.strip()
    files_list = [
        f for f in files_path.rglob("*" + suffix) if f.is_file()
    ]  # List files recursively

    if files_list:
        return files_list
    else:
        raise ValueError(
            f"The path {files_path} doesn't contain any file with this suffix: {suffix}"
        )


def read_db_config(filepath: PosixPath) -> tuple[PosixPath, PosixPath, PosixPath]:
    """ DEPRECATED
    Read content of a config file

    Args:
        filepath (PosixPath): absolute path to the db config file

    Returns:
        (db_user_path, db_pwd_path, db_docker_path) (tuple[PosixPath, PosixPath, PosixPath]): a tuple containing database config values
    """
    import configparser
    config = configparser.ConfigParser()  # Create a ConfigParser object
    config.read(filepath)  # Read the configuration file

    # Access values from the configuration file
    db_user_path = Path(config.get("postgresql", "user_absolute_path"))
    db_pwd_path = Path(config.get("postgresql", "pwd_absolute_path"))
    db_docker_path = Path(config.get("postgresql", "docker_absolute_path"))

    return (db_user_path, db_pwd_path, db_docker_path)


def _get_db_cred(
    user_path: PosixPath=None, pwd_path: PosixPath=None, docker_path: PosixPath=None
) -> dict[str, str | int]:
    """Get some database credentials

    Args:
        user_path (PosixPath): a path pointing to the file with the database user
        pwd_path (PosixPath): a path pointing to the file with the database user
        docker_path (PosixPath): a path pointing to the docker-compose file that implements the database

    Returns:
        config (dict[str, str|int]): a dictionary with database config values (i.e. user, pwd, database name and port)
    """
    if user_path is None and pwd_path is None and docker_path is None:
        # Get database credentials from environment variables
        user = open(os.environ["POSTGRES_DBUSER_FILE"], 'r').read()
        pwd = open(os.environ["POSTGRES_DBUSER_PASSWORD_FILE"], 'r').read()
        host = os.environ["POSTGRES_HOST"]
        db_name = os.environ["POSTGRES_DB"]
        port = os.environ["POSTGRES_DB_PORT"]
    else:  # Original behaivour
        import yaml
        with open(user_path, "r") as f:
            user = f.read()

        with open(pwd_path, "r") as f:
            pwd = f.read()

        with open(docker_path, "r") as f:
            docker_compose = yaml.safe_load(f)
        services = docker_compose["services"].keys()
        host = [x for x in services if "postgres" in x][0]
        db_name = docker_compose["services"]["postgres_db"]["environment"][
            "POSTGRES_DB"
        ]
        ports = docker_compose["services"]["postgres_db"]["ports"]  # Returns a list
        port = int(ports[0].split(":")[1])

    # Store database credentials in a dictionary
    config = {}
    config["user"] = user
    config["password"] = pwd
    config["host"] = host
    config["database"] = db_name
    config["port"] = port

    return config


def connect_db(
    db_config_filepath: PosixPath | None=None,
) -> tuple[psycopg2.extensions.connection, psycopg2.extensions.cursor]:
    """Connect to a Postgres database

    Args:
        db_config_filepath (PosixPath | None): absolute path to the db config file (deprecated)

    Returns:
        (conn, cur) (tuple[psycopg2.extensions.connection, psycopg2.extensions.cursor]): a tuple containing a connector to the Postgres database and a cursor object
    """
    import psycopg2
    if db_config_filepath:  # Original behaviour
        user_path, pwd_path, docker_path = read_db_config(db_config_filepath)
        db_config = _get_db_cred(user_path, pwd_path, docker_path)
    else: # Case when DB credentials are extracted from the environment variables
        db_config = _get_db_cred()
        
    try:
        conn = psycopg2.connect(**db_config)
        cur = conn.cursor()
    except (Exception, psycopg2.DatabaseError) as e:
        logger.error("Not able to connect to the database")
        logger.exception(e)
        raise
    else:
        logger.info("Connected to the database")
        return (conn, cur)


def insert_data_into_db(cur: psycopg2.extensions.cursor, db_table_name: str, data: dict) -> None:
    """Insert data into Postgres database

    Args:
        cur (psycopg2.extensions.cursor): a cursor object to execute Postgres command
        db_table_name (str): database table name where data are stored
        data (dict): data to be stored in the database
    """
    if not isinstance(data, dict):
        raise TypeError("""Data parameter has to be a dictionary.
                        Its keys have to be the table columns name""")

    table_col_names = ", ".join(
        data.keys()
    )  # Has to be in line with the SQL CREATE TABLE code
    table_values = ", ".join(map(lambda x: f"%({x})s", data.keys()))

    # SQL query
    query = f"""INSERT INTO {db_table_name} ({table_col_names})
                VALUES ({table_values})"""

    # Execute query
    cur.execute(query, data)


def read_data_from_db(db_config_filepath: PosixPath | None, sql_query: str) -> list[tuple]:
    """Read data from a database table

    Args:
        db_config_filepath (PosixPath | None): absolute path to the db config file (deprecated)
        sql_query (str): SQL query to run on database table

    Returns:
        res (list[tuple]): a list containing database table values in tuples
    """
    import psycopg2
    # Database connection
    conn, cur = connect_db(db_config_filepath)
    # Get table name
    db_table_name = sql_query.upper().split("FROM")[-1].strip().split(" ")[0]
    try:
        # Execute query
        cur.execute(sql_query)
        # Fetch results
        res = cur.fetchall()  # Returns a list of tuples
    except (Exception, psycopg2.Error) as e:
        logger.exception(e)
        raise
    finally:
        # Close database connection
        if conn:
            cur.close()
        conn.close()
        logger.info(f"Read data from {db_table_name.lower()} table")
        logger.info("Connection closed to the database")

    return res
