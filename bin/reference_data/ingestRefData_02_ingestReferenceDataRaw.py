import os
import sys
import json
import shutil
import re
from py7zr import SevenZipFile
from pathlib import Path
from common import utils

# Décompression des fichiers .7z dans un dossier intermédiaire
def decompress_files(data_folder, tmp_folder):
    files = ['out_Aircraft.7z', 'out_Airlines.7z', 'outFR_Airports.7z', 'outFR_Cities.7z', 'outFR_Countries.7z', 'outEN_Airports.7z', 'outEN_Cities.7z', 'outEN_Countries.7z']
    for file in files:
        file_path = os.path.join(data_folder, file)
        folder_name = os.path.join(tmp_folder, file.replace('.7z', 'Raw'))
        # Supprimer le dossier destination s'il existe déjà
        if os.path.exists(folder_name):
            shutil.rmtree(folder_name)
        os.makedirs(folder_name, exist_ok=True)
        with SevenZipFile(file_path, 'r') as archive:
            archive.extractall(path=folder_name)

def get_json_files(directory):
    json_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".json"):
                json_files.append(os.path.join(root, file))
    return json_files

# Insertion des données JSON dans la base de données
def ingest_data(tmp_folder, db_config_path):
    conn, cursor = utils.connect_db(db_config_path)

    folders = [f for f in os.listdir(tmp_folder) if f.endswith('Raw')]

    for folder in folders:
        nature = re.sub(r'out[A-Z]*_', '', folder).replace('Raw', '')
        table_name = f"refdata_{nature.lower()}_raw"
        folder_path = os.path.join(tmp_folder, folder)
        
        json_files = get_json_files(folder_path)
        for json_file in json_files:
            filename = os.path.basename(json_file)
            if filename.endswith('.json') and filename.startswith(f'{nature}_200_'):
                with open(json_file, 'r') as file:
                    data = json.load(file)
                    cursor.execute(f"INSERT INTO {table_name} (data) VALUES (%s)", [json.dumps(data)])
                    conn.commit()

    cursor.close()
    conn.close()

def clean_tmp_folder(tmp_folder):
    if os.path.exists(tmp_folder):
        shutil.rmtree(tmp_folder)

    db_config_path = Path(sys.argv[1])
    data_folder = sys.argv[2] if len(sys.argv) == 3 else "./"
    tmp_folder = os.path.join(data_folder, "tmp_ingest_raw_reference_data")

    # Créer le dossier intermédiaire
    os.makedirs(tmp_folder, exist_ok=True)

    decompress_files(data_folder, tmp_folder)
    ingest_data(tmp_folder, db_config_path)
    clean_tmp_folder(tmp_folder)
