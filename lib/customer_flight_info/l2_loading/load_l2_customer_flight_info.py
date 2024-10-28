# Only for test
import sys
sys.path.append("/home/ubuntu-user1/prj/dst_airlines_project/dst_airlines_de/lib")
#
import logging
import pandas as pd
import psycopg2
from collections.abc import Generator
from common import utils
from datetime import datetime, timedelta
from pathlib import Path, PosixPath

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def flatten_info(
    data_subset: dict[str, str], expected_keys: list[tuple[str, str]]
) -> dict[str, str]:
    """Read information from a subset of raw data to make them suitable for the cooked table

    Args:
        data_subset (dict[str, str]): data coming from 'Terminal' or 'Status' or 'OperatingCarrier' or 'Equipment' columns in raw table
        expected_keys (list[tuple[str, str]]): each tuple is composed of a key to read in raw data and its associated key to write in cooked table

    Returns:
        info (dict[str, str]): a dictionary returning formatted data according to cooked table schema
    """
    info = {}
    keys = data_subset.keys()
    for data_key, table_key in expected_keys:
        if data_key in keys:
            info[table_key] = data_subset[data_key]

    return info


def generate_datetime_info(
    data_subset: dict[str, str],
    airport_code: str,
    df_airports_data: pd.DataFrame,
) -> str:
    """Generate a datetime in proper format from a raw data subset having date and time information

    Args:
        data_subset (dict[str, str]): data coming from 'Scheduled' or 'Estimated' or 'Actual' columns in raw table
        airport_code (str): three characters airport code
        df_airports_data (pd.DataFrame): a Pandas DataFrame having airport and utc_offset data

    Returns:
        date_time (str): a string in datetime format YYYY-mm-ddTHH:MM
    """
    keys = data_subset.keys()
    if "DateTime" in keys:
        date_time = data_subset["DateTime"]  # UTC time of the airport
    elif "Date" in keys and "Time" in keys:
        date_time = (
            f'{data_subset["Date"]}T{data_subset["Time"]}'  # Local time of the airport
        )
        # Transform local time to UTC time of the airport
        utc_offset_airport = df_airports_data.loc[df_airports_data["airport"] == airport_code.upper().strip(), "utc_offset"]  # Returns a Pandas Series
        if not utc_offset_airport.empty:
            utc_offset = int(utc_offset_airport.values[0])
            date_time = datetime.strptime(date_time, "%Y-%m-%dT%H:%M") + timedelta(
                hours=utc_offset
            )
            date_time = date_time.strftime("%Y-%m-%dT%H:%M")
        else:
            pass
            # TODO: what to do if the utc offset is not available for a given airprot

    else:
        date_time = (
            f'{data_subset["Date"]}T{"00:00"}'  # Put default time value at 00:00
        )

    return date_time


def process_data(
    data_subset: dict[str, str | dict],
    key_name: str,
    df_airports_data: pd.DataFrame,
) -> dict[str, str]:
    """Process a subset of raw data to make them suitable for the cooked table

    Args:
        data_subset (dict[str, str | dict]): data coming from 'Departure' or 'Arrival' columns in raw table
        key_name (str): a string used in columns name of cooked table
        df_airports_data (pd.DataFrame): a Pandas DataFrame having airport and utc_offset data

    Returns:
        res (dict[str, str]): a dictionary returning formatted data according to cooked table schema
    """
    res = {}
    key_name = key_name.strip().lower()
    keys = data_subset.keys()
    if "AirportCode" in keys:
        res[f"{key_name}_airport_code"] = data_subset["AirportCode"].strip().upper()

    if "Scheduled" in keys:
        scheduled_date_time = generate_datetime_info(
            data_subset["Scheduled"],
            res[f"{key_name}_airport_code"],
            df_airports_data,
        )
        res[f"{key_name}_scheduled_datetime"] = scheduled_date_time

    if "Estimated" in keys:
        estimated_date_time = generate_datetime_info(
            data_subset["Estimated"],
            res[f"{key_name}_airport_code"],
            df_airports_data,
        )
        res[f"{key_name}_estimated_datetime"] = estimated_date_time

    if "Actual" in keys:
        actual_date_time = generate_datetime_info(
            data_subset["Actual"],
            res[f"{key_name}_airport_code"],
            df_airports_data,
        )
        res[f"{key_name}_actual_datetime"] = actual_date_time

    if "Terminal" in keys:
        # Create a list where each tuple is a pair between the raw data key and the table column name
        terminal_expected_keys = [
            ("Name", f"{key_name}_terminal_name"),
            ("Gate", f"{key_name}_terminal_gate"),
        ]
        terminal_info = flatten_info(data_subset["Terminal"], terminal_expected_keys)
        # Make values as uppercase
        terminal_info_upper = {k: v.strip().upper() for (k, v) in terminal_info.items()}
        res.update(terminal_info_upper)

    if "Status" in keys:
        # Create a list where each tuple is a pair between the raw data key and the table column name
        status_expected_keys = [
            ("Code", f"{key_name}_status_code"),
            ("Description", f"{key_name}_status_description"),
        ]
        status_info = flatten_info(data_subset["Status"], status_expected_keys)
        # Make a value as uppercase
        if f"{key_name}_status_code" in status_info:
            status_info[f"{key_name}_status_code"] = status_info[
                f"{key_name}_status_code"
            ].strip().upper()
        res.update(status_info)

    return res


def _build_flat_data(
    data: dict, df_airports_data: pd.DataFrame
) -> dict[str, str] | None:
    """Transform each key/value pairs coming from raw table to make them suitable for the cooked table

    Args:
        data (dict): data coming from 'data' column in raw table
        df_airports_data (pd.DataFrame): a Pandas DataFrame having airport and utc_offset data

    Returns:
        formatted_dict (dict[str, str]): a dictionary returning formatted data according to cooked table schema
    """
    formatted_dict = {}
    keys = data.keys()
    if "Departure" in keys:
        departure_data = process_data(
            data["Departure"], "Departure", df_airports_data
        )
        formatted_dict.update(departure_data)
    else:  # If 'Departure' key is not in raw data, exit this function (skip the file)
        return

    if "Arrival" in keys:
        arrival_data = process_data(
            data["Arrival"], "Arrival", df_airports_data
        )
        formatted_dict.update(arrival_data)
    else:  # If 'Arrival' key is not in raw data, exit this function (skip the file)
        return

    if "OperatingCarrier" in keys:
        # Create a list where each tuple is a pair between the raw data key and the table column name
        operating_carrier_expected_keys = [
            ("AirlineID", "operating_airline_id"),
            ("FlightNumber", "operating_flight_nb"),
        ]
        operating_carrier_info = flatten_info(
            data["OperatingCarrier"], operating_carrier_expected_keys
        )
        # Make values as uppercase
        operating_carrier_info_upper = {
            k: v.strip().upper() for (k, v) in operating_carrier_info.items()
        }
        formatted_dict.update(operating_carrier_info_upper)

    if "Equipment" in keys:
        # Create a list where each tuple is a pair between the raw data key and the table column name
        equipment_expected_keys = [("AircraftCode", "equipment_aircraft_code")]
        equipment_info = flatten_info(data["Equipment"], equipment_expected_keys)
        # Make values as uppercase
        equipment_info_upper = {k: v.strip().upper() for (k, v) in equipment_info.items()}
        formatted_dict.update(equipment_info_upper)

    if "Status" in keys:
        # Create a list where each tuple is a pair between the raw data key and the table column name
        overall_status_expected_keys = [
            ("Code", "overall_status_code"),
            ("Description", "overall_status_description"),
        ]
        overall_status_info = flatten_info(data["Status"], overall_status_expected_keys)
        # Make a value as uppercase
        if "overall_status_code" in overall_status_info:
            overall_status_info["overall_status_code"] = overall_status_info[
                "overall_status_code"
            ].strip().upper()
        formatted_dict.update(overall_status_info)

    return formatted_dict


def build_flat_data(
    all_data: list[tuple[dict]],
    df_airports_data: pd.DataFrame,
) -> Generator[dict, None, None]:
    """Format data coming from database raw table to make them suitable for the cooked table

    Args:
        all_data (list[tuple[dict]]): all raw data where the tuple is made of 1 element: data (dict)
        df_airports_data (pd.DataFrame): a Pandas DataFrame having airport and utc_offset data

    Returns:
        formatted_dict (Generator[dict, None, None]): a generator returning formatted data as a dictionary for each cooked table row
    """
    for tuple_data in all_data:
        data = tuple_data[0]
        formatted_dict = _build_flat_data(
            data, df_airports_data
        )
        if formatted_dict:
            yield formatted_dict


def ingest_data(
    db_config_filepath: PosixPath | None,
    sql_table_name_cooked: str,
    truncate_query: str,
    gen: Generator[dict, None, None],
) -> None:
    """Ingest data into Postgres database

    Args:
        db_config_filepath (PosixPath | None): absolute path to the db config file (deprecated)
        sql_table_name_cooked (str): SQL table name where raw cooked are stored
        truncate_query (str): SQL query to truncate cooked table
        gen (Generator[dict, None, None]): a generator returning formatted data as a dictionary
    """
    # Database connection
    conn, cur = utils.connect_db(db_config_filepath)

    # Remove all data from cooked table before filling it
    cur.execute(truncate_query)
    conn.commit()

    # Insert data into cooked table
    cnt = 1
    for cooked_data in gen:
        try:
            utils.insert_data_into_db(cur, sql_table_name_cooked, cooked_data)
            conn.commit()
            if cnt%1000==0:
                logger.info(f"{cnt} rows have been loaded into the database cooked table")
            cnt += 1
        except (Exception, psycopg2.Error) as e:
            # logger.exception(e)
            conn.rollback()
            continue

    # Close database connection
    if conn:
        cur.close()
    conn.close()
    logger.info(f"{cnt-1} rows have been loaded into the database cooked table")
    logger.info("Connection closed to the database")



if __name__ == "__main__":
    ########################
    ### Input parameters ###
    ########################
    db_config_filepath = None  # Set to None to maintain compatibility (deprecated)
    raw_table_name = "l1.operations_customer_flight_info"
    raw_data_query = f"SELECT DISTINCT data FROM {raw_table_name}"  # Use DISTINCT to get rid of duplicates

    cooked_airports_table_name = "l2.refdata_airports"
    cooked_airports_data_query = f"SELECT airport, utc_offset FROM {cooked_airports_table_name}"

    sql_table_name_cooked = "l2.operations_customer_flight_info"
    truncate_query = f"TRUNCATE TABLE {sql_table_name_cooked}"

    ########################
    # Read data from database l1.operations_customer_flight_info table
    all_data = utils.read_data_from_db(
        db_config_filepath, raw_data_query
    )  # Returns a list of tuples. The tuple is made of 1 element: data (dict)
    # Read data from database l2.refdata_airports table
    airports_data = utils.read_data_from_db(
        db_config_filepath, cooked_airports_data_query
    )  # Returns a list of tuples. The tuple is made of 2 elements: airport (str) and utc_offset (int)
    df_airports_data = pd.DataFrame(airports_data, columns=("airport", "utc_offset"))  # Pandas DataFrame
    # Build data structure for cooked table
    gen = build_flat_data(
        all_data, df_airports_data
    )  # Generator object
    # Ingest data into cooked table
    ingest_data(db_config_filepath, sql_table_name_cooked, truncate_query, gen)
    logger.info("COOKED LOADING COMPLETED !")
