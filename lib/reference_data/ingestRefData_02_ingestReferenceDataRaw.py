import os
import sys
import json
import shutil
import re
from py7zr import SevenZipFile
from pathlib import Path
from common import utils
import logging

# Configuration du logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Dictionnaire pour pouvoir traiter les differentes structures de fichiers JSON en fonction de la nature des donnees
NATURE_PATHS = {
    "airports": ["AirportResource", "Airports", "Airport"],
    "countries": ["CountryResource", "Countries", "Country"],
    "cities": ["CityResource", "Cities", "City"],
    "airlines": ["AirlineResource", "Airlines", "Airline"],
    "aircraft": ["AircraftResource", "AircraftSummaries", "AircraftSummary"]
}

def decompress_files(data_folder, tmp_folder):
    files = ['out_Aircraft.7z', 'out_Airlines.7z', 'outFR_Airports.7z', 'outFR_Cities.7z', 'outFR_Countries.7z', 'outEN_Airports.7z', 'outEN_Cities.7z', 'outEN_Countries.7z']
    for file in files:
        file_path = os.path.join(data_folder, file)
        logging.info(f"ReferenceData, RAW DATA, ingestion, processing file : {file_path}")
        if not os.path.exists(file_path):
            logging.error(f"ReferenceData, RAW DATA, ingestion, file not found : {file_path}")
            continue
        folder_name = os.path.join(tmp_folder, file.replace('.7z', 'Raw'))
        # Supprimer le dossier destination s'il existe déjà
        if os.path.exists(folder_name):
            try:
                shutil.rmtree(folder_name)
                logging.info(f"ReferenceData, RAW DATA, ingestion, deleted directory : {folder_name}")
            except Exception as e:
                logging.error(f"ReferenceData, RAW DATA, ingestion, error deleting directory : {e}")
                continue
        try:
            os.makedirs(folder_name, exist_ok=True)
            logging.info(f"ReferenceData, RAW DATA, ingestion, new directory : {folder_name}")
        except Exception as e:
            logging.error(f"ReferenceData, RAW DATA, ingestion, error creating directory : {e}")
            continue
        try:
            with SevenZipFile(file_path, 'r') as archive:
                archive.extractall(path=folder_name)
                logging.info(f"ReferenceData, RAW DATA, ingestion, file extracted : {file_path} -> {folder_name}")
        except Exception as e:
            logging.error(f"ReferenceData, RAW DATA, ingestion, error extracting : {e}")

def get_json_files(directory):
    json_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".json"):
                json_files.append(os.path.join(root, file))
    return json_files

def get_data_by_nature(data, nature):
    """ Récupère les données en fonction de la 'nature' à partir de la structure JSON. """
    path = NATURE_PATHS.get(nature.lower())
    if not path:
        logging.error(f"Unknown nature: {nature}")
        return []

    # Suivre le chemin dans le JSON pour récupérer la liste des éléments
    extracted_data = data
    try:
        for key in path:
            extracted_data = extracted_data.get(key, {})
        # On s'assure d'avoir toujours une liste, même si c'est un unique élément
        if isinstance(extracted_data, dict):
            extracted_data = [extracted_data]
        return extracted_data
    except Exception as e:
        logging.error(f"Error extracting data for nature {nature}: {e}")
        return []

def ingest_data(tmp_folder, db_config_path=None):
    try:
        # Connexion à la base de données
        conn, cursor = utils.connect_db(db_config_path)
        logging.info("ReferenceData, RAW DATA, ingestion, connexion to the database OK")
    except Exception as e:
        logging.error(f"ReferenceData, RAW DATA, ingestion, error connecting to the database : {e}")
        return

    folders = [f for f in os.listdir(tmp_folder) if f.endswith('Raw')]
    for folder in folders:
        nature = re.sub(r'out[A-Z]*_', '', folder).replace('Raw', '')
        table_name = f"l1.refdata_{nature.lower()}"
        folder_path = os.path.join(tmp_folder, folder)
        
        json_files = get_json_files(folder_path)
        for json_file in json_files:
            filename = os.path.basename(json_file)
            if filename.endswith('.json') and filename.startswith(f'{nature}_200_'):
                try:
                    with open(json_file, 'r') as file:
                        data = json.load(file)
                        # Utilisation de la fonction pour récupérer les données selon la 'nature'
                        items = get_data_by_nature(data, nature)

                        # Insérer chaque élément séparément
                        for item in items:
                            cursor.execute(f"INSERT INTO {table_name} (data) VALUES (%s)", [json.dumps(item)])
                            conn.commit()
                            # logging.info(f"Inserted {nature} data from {json_file} into {table_name}")

                except Exception as e:
                    logging.error(f"ReferenceData, RAW DATA, ingestion, error inserting data from {json_file} : {e}")

    try:
        cursor.close()
        conn.close()
        logging.info("ReferenceData, RAW DATA, ingestion, connexion to the database closed")
    except Exception as e:
        logging.error(f"ReferenceData, RAW DATA, ingestion, error closing database : {e}")

def clean_tmp_folder(tmp_folder):
    if os.path.exists(tmp_folder):
        try:
            shutil.rmtree(tmp_folder)
            logging.info(f"ReferenceData, RAW DATA, ingestion, temporary directory deleted : {tmp_folder}")
        except Exception as e:
            logging.error(f"ReferenceData, RAW DATA, ingestion, error deleting temporary directory : {e}")

if __name__ == "__main__":
    db_config_path = None
    data_folder = os.environ['DATA_FOLDER']
    tmp_folder = os.path.join(data_folder, "tmp_ingest_raw_reference_data")

    # Créer le dossier intermédiaire
    try:
        os.makedirs(tmp_folder, exist_ok=True)
        logging.info(f"ReferenceData, RAW DATA, ingestion, temporary directory created : {tmp_folder}")
    except Exception as e:
        logging.error(f"ReferenceData, RAW DATA, ingestion, error creating temporary directory : {e}")
        sys.exit(1)

    decompress_files(data_folder, tmp_folder)
    ingest_data(tmp_folder, db_config_path)
    clean_tmp_folder(tmp_folder)
