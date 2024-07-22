import configparser
import logging
import psycopg2
import yaml
from pathlib import Path, PosixPath
from psycopg2.extensions import connection, cursor

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


def read_db_config(filepath: PosixPath) -> tuple[PosixPath, PosixPath, PosixPath, str]:
    """Read content of a config file

    Args:
        filepath (PosixPath): absolute path to the db config file

    Returns:
        (db_user_path, db_pwd_path, db_docker_path, db_host) (tuple[PosixPath, PosixPath, PosixPath, str]): a tuple containing database config values
    """
    config = configparser.ConfigParser()  # Create a ConfigParser object
    config.read(filepath)  # Read the configuration file

    # Access values from the configuration file
    db_user_path = Path(config.get("postgresql", "user_absolute_path"))
    db_pwd_path = Path(config.get("postgresql", "pwd_absolute_path"))
    db_docker_path = Path(config.get("postgresql", "docker_absolute_path"))
    db_host = config.get("postgresql", "host")

    return (db_user_path, db_pwd_path, db_docker_path, db_host)


def _get_db_cred(
    user_path: PosixPath, pwd_path: PosixPath, docker_path: PosixPath, host: str
) -> dict[str, str | int]:
    """Get some database credentials

    Args:
        user_path (PosixPath): a path pointing to the file with the database user
        pwd_path (PosixPath): a path pointing to the file with the database user
        docker_path (PosixPath): a path pointing to the docker-compose file that implements the database
        host (str): database server address (e.g. localhost or an IP address)

    Returns:
        config (dict[str, str|int]): a dictionary with database config values (i.e. user, pwd, database name and port)
    """
    with open(user_path, "r") as f:
        user = f.read()

    with open(pwd_path, "r") as f:
        pwd = f.read()

    with open(docker_path, "r") as f:
        docker_compose = yaml.safe_load(f)
        db_name = docker_compose["services"]["postgres_db"]["environment"][
            "POSTGRES_DB"
        ]
        ports = docker_compose["services"]["postgres_db"]["ports"]  # Returns a list
        port = int(ports[0].split(":")[0])

    # Store database credentials in a dictionary
    config = {}
    config["user"] = user
    config["password"] = pwd
    config["database"] = db_name
    config["port"] = port
    config["host"] = host

    return config


def connect_db(
    db_config_filepath: PosixPath,
) -> tuple[psycopg2.connection, psycopg2.cursor]:
    """Connect to a Postgres database

    Args:
        db_config_filepath (PosixPath): absolute path to the db config file

    Returns:
        (conn, cur) (tuple[psycopg2.connection, psycopg2.cursor]): a tuple containing a connector to the Postgres database and a cursor object
    """
    user_path, pwd_path, docker_path, host = read_db_config(db_config_filepath)
    db_config = _get_db_cred(user_path, pwd_path, docker_path, host)

    try:
        conn = psycopg2.connect(**db_config)
        cur = conn.cursor()
    except (psycopg2.DatabaseError, Exception) as e:
        logger.error("Not able to connect to the database")
        logger.exception(e)
        raise ValueError
    else:
        logger.info("Connected to the database")
        return (conn, cur)


def insert_data_into_db(cur: psycopg2.cursor, db_table_name: str, data: dict) -> None:
    """Insert data into Postgres database

    Args:
        cur (psycopg2.cursor): a cursor object to execute Postgres command
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

    # Create SQL query
    query = f"""INSERT INTO {db_table_name} ({table_col_names})
                VALUES ({table_values})"""
    # Execute query
    cur.execute(query, data)
