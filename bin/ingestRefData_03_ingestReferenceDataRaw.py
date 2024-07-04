import os
import getpass
import json
import shutil
import psycopg2
import re
from py7zr import SevenZipFile

db_user = 'dst_designer'
password = getpass.getpass(f"Enter the password for the PostgreSQL user {db_user}: ")

# Configuration de la connexion à la base de données
db_config = {
    'dbname': 'dst_airlines_db',
    'user': db_user,
    'password': password,
    'host': 'localhost',
    'port': 6432
}

# Décompression des fichiers .7z
def decompress_files():
    files = ['out_Aircraft.7z', 'out_Airlines.7z', 'outFR_Airports.7z', 'outFR_Cities.7z', 'outFR_Countries.7z', 'outEN_Airports.7z', 'outEN_Cities.7z', 'outEN_Countries.7z']
    for file in files:
        folder_name = file.replace('.7z', 'Raw')
        # Supprimer le dossier destination s'il existe déjà
        if os.path.exists(folder_name):
            shutil.rmtree(folder_name)
        os.makedirs(folder_name, exist_ok=True)
        with SevenZipFile(file, 'r') as archive:
            archive.extractall(path=folder_name)

def get_json_files(directory):
    json_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".json"):
                json_files.append(os.path.join(root, file))
    return json_files

# Insertion des données JSON dans la base de données
def ingest_data():
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()

    folders = [f for f in os.listdir() if f.endswith('Raw')]

    for folder in folders:
        nature = re.sub(r'out[A-Z]*_', '', folder).replace('Raw', '')
        table_name = f"refdata_{nature.lower()}_raw"

        json_files = get_json_files(folder)
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
    decompress_files()
    ingest_data()