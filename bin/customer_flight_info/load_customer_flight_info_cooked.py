import json
import logging
import utils
from collections import defaultdict
from pathlib import Path, PosixPath
from typing import Generator

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def get_data(files_list: list[PosixPath]) -> Generator[dict, None, None]:
    """Return data of each file one by one

    Args:
        files_list (list[PosixPath]): a list containing paths of JSON files

    Returns:
        data (Generator[dict, None, None]): a generator returning data for each file as a dictionary
    """
    for f in files_list:
        with open(f, "r") as data_file:
            data = json.load(data_file)
            yield data


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


def build_flat_data(data: dict) -> dict[str, str]:
    data_flight = data["FlightInformation"]["Flights"]["Flight"]
    if isinstance(data_flight, dict):
        formatted_dict = _build_flat_data(data_flight)
    elif isinstance(data_flight, list):
        for elem in data_flight:
            formatted_dict = _build_flat_data(elem)
    else:
        logging.error("The format has to be a dictionary or a list")
        raise TypeError("The format has to be a dictionary or a list")

    return formatted_dict


# def write_data_to_db(data: dict, conn: psycopg2.connection) -> None:
#     # Create a cursor
#     with conn.cursor() as cur:
#         query = f"""
#                 INSERT INTO operations_customer_flight_info ({", ".join(data.keys())})
#                 VALUES ({", ".join(map(lambda x: f"%({x})s", data.keys()))})
#                 """
#         try:
#             cur.execute(query, data)
#         except (Exception, psycopg2.DatabaseError) as e:
#             print(e)


if __name__ == "__main__":
    # Absolute root path where the data are stored
    # data_absolute_path = Path("/home/ubuntu/DST_airlines/dst_airlines_de/data/customerFlightInfo")
    data_absolute_path = Path("/config/workspace/lufthansa/data/2024-07-03")
    db_user_absolute_path = Path(
        "/home/ubuntu/DST_airlines/dst_airlines_de/src/project_deployment_postgres/postgres_user.txt"
    )
    db_pwd_absolute_path = Path(
        "/home/ubuntu/DST_airlines/dst_airlines_de/src/project_deployment_postgres/postgres_password.txt"
    )
    # db_docker_absolute_path = Path("/home/ubuntu/DST_airlines/dst_airlines_de/src/project_deployment_postgres/docker-compose.yml")
    db_docker_absolute_path = Path("/config/workspace/lufthansa/docker-compose.yml")
    files_list = utils.get_filenames(data_absolute_path, "json")
    print(files_list)
    gen = get_data(files_list)  # Generator object
    # conn = utils.connect_db(user_path, pwd_path, docker_path)  # Connect to the db
    for d in gen:
        print(f"{d=}")
        data_to_write = build_flat_data(d)
        print(f"{data_to_write=}")
        # write_data_to_db(data_to_write, conn)
    # conn.close()
