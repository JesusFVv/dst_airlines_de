# cooked
import logging
from common import utils
from pathlib import Path, PosixPath
from typing import Generator

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def generate_datetime_info(data_subset: dict[str, str]) -> str:
    """Generate a datetime in proper format from raw data

    Args:
        data_subset (dict[str, str]): subset of raw data having date and time information

    Returns:
        date_time (str): a string in datetime format YYYY-mm-dd HH:MM
    """
    keys = data_subset.keys()
    if "DateTime" in keys:
        date_time = data_subset["DateTime"]  # UTC time of the airport
    elif "Date" in keys and "Time" in keys:
        date_time = f'{data_subset["Date"]} {data_subset["Time"]}'  # Local time of the airport
    else:
        date_time = f'{data_subset["Date"]} {"00:00"}'  # Put default time value at 00:00

    return date_time


def read_info(data_subset: dict[str, str], expected_keys: list[tuple[str, str]]) -> dict[str, str]:
    """Read information from raw data

    Args:
        data_subset (dict[str, str]): subset of raw data
        expected_keys (list[tuple[str, str]]): each tuple is composed of a key to read in raw data and its associated key to write in cooked table
    
    Returns:
        info (dict[str, str]): a dictionary with extracted info for the cooked table where its keys are the column names and its values are table values
    """
    info = {}
    keys = data_subset.keys()
    for data_key, table_key in expected_keys:
        if data_key in keys:
            info[table_key] = data_subset[data_key]
    
    return info


def process_data(data_subset: dict[str, str | dict], key_name: str):
    res = {}
    key_name = key_name.strip().lower()
    keys = data_subset.keys()
    if "AirportCode" in keys:
        res[f"{key_name}_airport_code"] = data_subset["AirportCode"]

    if "Scheduled" in keys:
        scheduled_date_time = generate_datetime_info(data_subset["Scheduled"])
        res[f"{key_name}_scheduled_datetime"] = scheduled_date_time

    if "Estimated" in keys:
        estimated_date_time = generate_datetime_info(data_subset["Estimated"])
        res[f"{key_name}_estimated_datetime"] = estimated_date_time
    
    if "Actual" in keys:
        actual_date_time = generate_datetime_info(data_subset["Actual"])
        res[f"{key_name}_actual_datetime"] = actual_date_time

    if "Terminal" in keys:
        # Create a list where each tuple is a pair between the raw data key and the table column name
        terminal_expected_keys = [("Name", f"{key_name}_terminal_name"), ("Gate", f"{key_name}_terminal_gate")]
        terminal_info = read_info(data_subset["Terminal"], terminal_expected_keys)
        res.update(terminal_info)
    
    if "Status" in keys:
        # Create a list where each tuple is a pair between the raw data key and the table column name
        status_expected_keys = [("Code", f"{key_name}_status_code"), ("Description", f"{key_name}_status_description")]
        status_info = read_info(data_subset["Status"], status_expected_keys)
        res.update(status_info)

    return res


def _build_flat_data(data: dict) -> dict[str, str]:
    formatted_dict = {}
    keys = data.keys()
    if "Departure" in keys:
        departure_data = process_data(data["Departure"], "Departure")
        formatted_dict.update(departure_data)

    if "Arrival" in keys:
        arrival_data = process_data(data["Arrival"], "Arrival")
        formatted_dict.update(arrival_data)
    
    if "OperatingCarrier" in keys:
        # Create a list where each tuple is a pair between the raw data key and the table column name
        operating_carrier_expected_keys = [("AirlineID", "operating_airline_id"), ("FlightNumber", "operating_flight_nb")]
        operating_carrier_info = read_info(data["OperatingCarrier"], operating_carrier_expected_keys)
        formatted_dict.update(operating_carrier_info)
    
    if "Equipment" in keys:
        # Create a list where each tuple is a pair between the raw data key and the table column name
        equipment_expected_keys = [("AircraftCode", "equipment_aircraft_code")]
        equipment_info = read_info(data["Equipment"], equipment_expected_keys)
        formatted_dict.update(equipment_info)

    if "Status" in keys:
        # Create a list where each tuple is a pair between the raw data key and the table column name
        overall_status_expected_keys = [("Code", "overall_status_code"), ("Description", "overall_status_description")]
        overall_status_info = read_info(data["Status"], overall_status_expected_keys)
        formatted_dict.update(overall_status_info)
    
    return formatted_dict


def build_flat_data(all_data: list[tuple[int, dict]]) -> Generator[dict, None, None]:
    """Format data coming from database raw table to make them suitable for the cooked table

    Args:
        all_data (list[tuple[int, dict]]): all raw data where the tuple is made of 2 elements: id (int) and data (dict)

    Returns:
        formatted_dict (Generator[dict, None, None]): a generator returning formatted data as a dictionary for each database table row
    """
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
    # Read data from the database raw table
    all_data = utils.read_data_from_db(db_config_filepath, sql_query)  # Returns a list of tuples. The tuple is made of 2 elements: id (int) and data (dict)
    gen = build_flat_data(all_data)  # Generator object


# [
#     (1, {'Status': {'Code': 'LD', 'Description': 'Flight Landed'}, 'Arrival': {'Actual': {'Date': '2024-07-06', 'Time': '07:52'}, 'Status': {'Code': 'LD', 'Description': 'Flight Landed'}, 'Scheduled': {'Date': '2024-07-06', 'Time': '07:50'}, 'AirportCode': 'ZAD'}, 'Departure': {'Actual': {'Date': '2024-07-06', 'Time': '06:17'}, 'Status': {'Code': 'DP', 'Description': 'Flight Departed'}, 'Terminal': {'Gate': 'B15', 'Name': '1'}, 'Scheduled': {'Date': '2024-07-06', 'Time': '06:10'}, 'AirportCode': 'BER'}, 'Equipment': {'AircraftCode': '320'}, 'OperatingCarrier': {'AirlineID': '4X', 'FlightNumber': '8964'}}),
#     (2, {'Status': {'Code': 'LD', 'Description': 'Flight Landed'}, 'Arrival': {'Actual': {'Date': '2024-07-06', 'Time': '22:45'}, 'Status': {'Code': 'LD', 'Description': 'Flight Landed'}, 'Scheduled': {'Date': '2024-07-06', 'Time': '22:05'}, 'AirportCode': 'WAW'}, 'Departure': {'Actual': {'Date': '2024-07-06', 'Time': '21:16'}, 'Status': {'Code': 'DP', 'Description': 'Flight Departed'}, 'Terminal': {'Gate': 'A13', 'Name': '1'}, 'Scheduled': {'Date': '2024-07-06', 'Time': '20:30'}, 'AirportCode': 'FRA'}, 'Equipment': {'AircraftCode': '32A'}, 'OperatingCarrier': {'AirlineID': 'LH', 'FlightNumber': '1352'}, 'MarketingCarrierList': {'MarketingCarrier': [{'AirlineID': 'A3', 'FlightNumber': '1474'}, {'AirlineID': 'NH', 'FlightNumber': '5887'}]}}),
#     (3, {'Status': {'Code': 'LD', 'Description': 'Flight Landed'}, 'Arrival': {'Actual': {'Date': '2024-07-06', 'Time': '23:32'}, 'Status': {'Code': 'LD', 'Description': 'Flight Landed'}, 'Scheduled': {'Date': '2024-07-06', 'Time': '22:05'}, 'AirportCode': 'WAW'}, 'Departure': {'Actual': {'Date': '2024-07-06', 'Time': '22:07'}, 'Status': {'Code': 'DP', 'Description': 'Flight Departed'}, 'Terminal': {'Gate': 'G43', 'Name': '2'}, 'Scheduled': {'Date': '2024-07-06', 'Time': '20:35'}, 'AirportCode': 'MUC'}, 'Equipment': {'AircraftCode': '31K'}, 'OperatingCarrier': {'AirlineID': 'CL', 'FlightNumber': '1616'}, 'MarketingCarrierList': {'MarketingCarrier': [{'AirlineID': 'A3', 'FlightNumber': '1507'}, {'AirlineID': 'LO', 'FlightNumber': '4908'}, {'AirlineID': 'UA', 'FlightNumber': '9495'}, {'AirlineID': 'WY', 'FlightNumber': '5291'}]}})
# ]
