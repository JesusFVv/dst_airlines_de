import json
import logging
import psycopg2
import shutil
from collections.abc import Generator
from common import utils
from pathlib import Path, PosixPath
from psycopg2.extras import Json
from py7zr import SevenZipFile

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def unzip_7z_files(data_path: PosixPath) -> None:
    """Unzip 7z files into an output folder

    Args:
        data_path (PosixPath): absolute path to the root folder having 7z files
    """
    files_list = utils.get_filenames(data_path, "2024-07-0*.7z")
    for f in files_list:
        folder_name = f.with_name(f.stem + "Raw")  # Replace .7z extension by 'Raw'
        # Delete destination folder if it already exists
        if folder_name.exists():
            shutil.rmtree(folder_name)
        folder_name.mkdir()  # Create output folder
        # Store extracted data in output folder
        with SevenZipFile(f, "r") as archive:
            archive.extractall(path=folder_name)


def get_data(data_path: PosixPath) -> Generator[dict, None, None]:
    """Get data from JSON files

    Args:
        data_path (PosixPath): absolute path to the root folder having data in JSON format

    Returns:
        (Generator[dict, None, None]): a generator returning data as a dictionary for each file
    """
    folders = [
        x for x in data_path.iterdir() if x.is_dir() and x.match("*Raw")
    ]  # List folders
    for folder in folders:
        json_files = utils.get_filenames(folder, "json")  # List JSON files
        for json_file in json_files:
            # Read JSON file
            with open(json_file, "r") as f:
                data = json.load(f)
            data_flight = data["FlightInformation"]["Flights"]["Flight"]

            if isinstance(data_flight, dict):
                yield data_flight
            elif isinstance(data_flight, list):
                for elem in data_flight:
                    yield elem
            else:
                raise TypeError("The format has to be a dictionary or a list")


def ingest_data(
    db_config_filepath: PosixPath,
    sql_table_name_raw: str,
    truncate_query: str,
    gen: Generator[dict, None, None],
) -> None:
    """Ingest data into Postgres database

    Args:
        db_config_filepath (PosixPath): absolute path to the db config file
        sql_table_name_raw (str): SQL table name where raw data are stored
        truncate_query (str): SQL query to truncate raw table
        gen (Generator[dict, None, None]): a generator returning data as a dictionary
    """
    # Database connection
    conn, cur = utils.connect_db(db_config_filepath)

    # Remove all data from raw table before filling it
    cur.execute(truncate_query)
    conn.commit()

    # Insert data into raw table
    try:        
        for idx, data in enumerate(gen, start=1):
            raw_data = {"data": Json(data)}  # Create a dictionary with a key 'data' that is the column name in postgres raw table
            utils.insert_data_into_db(cur, sql_table_name_raw, raw_data)
            conn.commit()
            if idx%1000==0:
                logger.info(f"{idx} rows have been loaded into the database raw table")
    except (Exception, psycopg2.Error) as e:
        logger.exception(e)
        conn.rollback()
    finally:
        # Close database connection
        if conn:
            cur.close()
        conn.close()
        logger.info(f"{idx} rows have been loaded into the database raw table")
        logger.info("Connection closed to the database")


if __name__ == "__main__":
    ########################
    ### Input parameters ###
    ########################
    data_path = Path("/home/ubuntu/dst_airlines_de/data/customerFlightInfo")
    db_config_filepath = Path(
        "/home/ubuntu/dst_airlines_de/bin/customer_flight_info/raw_loading/common/database.ini"
    )
    sql_table_name_raw = "l1.operations_customer_flight_info"
    truncate_query = f"TRUNCATE TABLE {sql_table_name_raw}"

    ########################
    unzip_7z_files(data_path)
    gen = get_data(data_path)  # Generator object
    ingest_data(db_config_filepath, sql_table_name_raw, truncate_query, gen)
    logger.info("RAW LOADING COMPLETED !")

