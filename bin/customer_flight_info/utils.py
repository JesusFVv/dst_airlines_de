import configparser
import logging
import psycopg2
import yaml
from pathlib import Path, PosixPath

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def read_db_config(filepath: PosixPath) -> tuple[PosixPath, ...]:
    """Read content of a config file

    Args:
        filepath (PosixPath): absolute path where the config file is stored

    Returns:
        (db_user_path, db_pwd_path, db_docker_path) (tuple[PosixPath, ...]): a tuple containing database config values
    """
    config = configparser.ConfigParser()  # Create a ConfigParser object
    config.read(filepath)  # Read the configuration file
 
    # Access values from the configuration file
    db_user_path = Path(config.get('Database', 'user_absolute_path'))
    db_pwd_path = Path(config.get('Database', 'pwd_absolute_path'))
    db_docker_path = Path(config.get('Database', 'docker_absolute_path'))
 
    return (db_user_path, db_pwd_path, db_docker_path)
 

def get_filenames(data_path: PosixPath, file_extension: str = "") -> list[PosixPath]:
    """Get a list of filenames recursively

    Args:
        data_path (PosixPath): absolute root path where the data are stored
        file_extension (str): filter by the given file_extension

    Returns:
        files_list (list[PosixPath]): a list containing path of files
    """
    if file_extension:
        file_extension = "." + file_extension

    files_list = [
        f for f in data_path.rglob("*" + file_extension) if f.is_file()
    ]  # List files recursively

    if files_list:
        return files_list
    else:
        raise ValueError(
            f"The path {data_path} doesn't contain any {file_extension} file"
        )


def _get_db_cred(
    user_path: PosixPath, pwd_path: PosixPath, docker_path: PosixPath
) -> tuple[str, str, str, int]:
    """Get some database credentials

    Args:
        user_path (PosixPath): a path pointing to the file with the database user
        pwd_path (PosixPath): a path pointing to the file with the database user
        docker_path (PosixPath): a path pointing to the docker-compose file that implements the database

    Returns:
        (user, pwd, db_name, port) (tuple[str, str, str, int]): a tuple with user, pwd, database name and port information
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

    return (user, pwd, db_name, port)


def connect_db(db_config_file: PosixPath) -> psycopg2.connection:
    """Connect to a Postgres database

    Args:
        user_path (PosixPath): absolute path where the file containing database user is stored
        pwd_path (PosixPath): absolute path where the file containing database password is stored
        docker_path (PosixPath): absolute path where the docker compose file is stored

    Returns:
        conn (psycopg2.connection): a connector to the Postgres database
    """
    user_path, pwd_path, docker_path = read_db_config(db_config_file)
    user, pwd, db_name, port = _get_db_cred(user_path, pwd_path, docker_path)

    try:
        conn = psycopg2.connect(
            dbname=db_name, user=user, password=pwd, host="localhost", port=port
        )
    except Exception as e:
        logger.error("Not able to connect to the database")
        logger.exception(e)
        return

    return conn
