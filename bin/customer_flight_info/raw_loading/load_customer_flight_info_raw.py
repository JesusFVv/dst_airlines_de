import json
import logging
import shutil
import utils
from pathlib import Path, PosixPath
from py7zr import SevenZipFile
from typing import Generator

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def unzip_7z_files(data_path: PosixPath) -> None:
    """Unzip 7z files into an output folder

    Args:
        data_path (PosixPath): absolute path to the 7z files
    """
    files_list = utils.get_filenames(data_path, "7z")
    for f in files_list:
        folder_name = f.replace(".7z", "Raw")
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
        data_path (PosixPath): absolute path to folders having data in JSON format

    Returns:
        (Generator[dict, None, None]): a generator returning data for each file as a dictionary
    """
    folders = [x for x in data_path.iterdir() if x.is_dir() and x.endswith("Raw")]
    for folder in folders:
        json_files = utils.get_filenames(folder, "json")
        for json_file in json_files:
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


def ingest_data(sql_table_name_raw: str, data: dict) -> None:
    """Ingest data into Postgres database

    Args:
        sql_table_name_raw (str): SQL table name where data are stored
        data (dict): a dictionary storing JSON file data
    """
    # Database connection
    conn, cur = utils.connect_db(db_config_filepath)

    try:
        utils.insert_data_into_db(cur, sql_table_name_raw, data)
    except Exception as e:
        logger.exception(e)
        conn.rollback()
    finally:
        if conn:
            cur.close()
        conn.close()


if __name__ == "__main__":
    ########################
    ### Input parameters ###
    ########################
    data_path = Path("/home/ubuntu/dst_airlines_de/data/customerFlightInfo")
    db_config_filepath = Path(
        "/home/ubuntu/dst_airlines_de/bin/customer_flight_info/database.ini"
    )
    sql_table_name_raw = "operations_customer_flight_info_raw"

    ########################
    unzip_7z_files(data_path)
    gen = get_data(data_path)  # Generator object
    for data in gen:
        ingest_data(sql_table_name_raw, data)
