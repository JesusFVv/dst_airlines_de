import os
import sys
import json
import shutil
import re
from py7zr import SevenZipFile
from pathlib import Path
from common import utils

# Décompression des fichiers .7z
def decompress_files(data_folder):
    files = ['out_Aircraft.7z', 'out_Airlines.7z', 'outFR_Airports.7z', 'outFR_Cities.7z', 'outFR_Countries.7z', 'outEN_Airports.7z', 'outEN_Cities.7z', 'outEN_Countries.7z']
    for file in files:
        file_path = os.path.join(data_folder, file)
        folder_name = os.path.join(data_folder, file.replace('.7z', 'Raw'))
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
def ingest_data(data_folder, db_config_path):
    conn, cursor = utils.connect_db(db_config_path)

    folders = [f for f in os.listdir(data_folder) if f.endswith('Raw')]

    for folder in folders:
        nature = re.sub(r'out[A-Z]*_', '', folder).replace('Raw', '')
        table_name = f"refdata_{nature.lower()}_raw"
        folder_path = os.path.join(data_folder, folder)
        
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

if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print(f"Usage: {sys.argv[0]} <DB_CONFIG_PATH> [DATA_FOLDER]")
        sys.exit(1)

    db_config_path = Path(sys.argv[1])
    data_folder = sys.argv[2] if len(sys.argv) == 3 else "./"

    decompress_files(data_folder)
    ingest_data(data_folder, db_config_path)
