import logging
from collections import defaultdict
from common import utils
from pathlib import Path, PosixPath
from typing import Generator

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def _build_flat_data(data: dict) -> dict[str, str]:
    formatted_dict = defaultdict(str)
    keys = data.keys()
    print(keys)
    if "Departure" in keys:
        departure_keys = data["Departure"].keys()
        if "AirportCode" in departure_keys:
            formatted_dict["departure_airport_code"] = data["Departure"]["AirportCode"]

        if "Scheduled" in departure_keys:
            scheduled_keys = data["Departure"]["Scheduled"].keys()
            if "Date" in scheduled_keys and "Time" in scheduled_keys:
                formatted_dict["departure_datetime"] = (
                    f'{data["Departure"]["Scheduled"]["Date"]} {data["Departure"]["Scheduled"]["Time"]}'
                )
            else:
                formatted_dict["departure_datetime"] = (
                    f'{data["Departure"]["Scheduled"]["Date"]} {"00:00"}'
                )

    return formatted_dict


def build_flat_data(db_config_filepath: PosixPath, sql_query: str) -> Generator[dict, None, None]:
    """Format data coming from database raw table to make them suitable for the cooked table

    Args:
        db_config_filepath (PosixPath): absolute path to the db config file
        sql_query (str): SQL query to run on database table

    Returns:
        formatted_dict (Generator[dict, None, None]): a generator returning formatted data as a dictionary for each database table row
    """
    # Read data from the database raw table
    all_data = utils.read_data_from_db(db_config_filepath, sql_query)  # Returns a list of tuples. The tuple is made of 2 elements: id (int) and data (dict)
    for _, data in all_data:
        formatted_dict = _build_flat_data(data)
        yield formatted_dict


def ingest_data(
    db_config_filepath: PosixPath,
    sql_table_name_cooked: str,
    gen: Generator[dict, None, None],
) -> None:
    """Ingest data into Postgres database

    Args:
        db_config_filepath (PosixPath): absolute path to the db config file
        sql_table_name_cooked (str): SQL table name where cooked data are stored
        gen (Generator[dict, None, None]): a generator returning formatted data as a dictionary
    """
    # Database connection
    conn, cur = utils.connect_db(db_config_filepath)




if __name__ == "__main__":
    ########################
    ### Input parameters ###
    ########################
    db_config_filepath = Path(
        "/home/ubuntu/dst_airlines_de/bin/customer_flight_info/cooked_loading/common/database.ini"
    )
    sql_query = "SELECT * FROM operations_customer_flight_info_raw"

    ########################
    build_flat_data(db_config_filepath, sql_query)

