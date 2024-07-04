import sys
import os
import getpass
import psycopg2

def execute_sql_script(sql_script, db_user, db_name, db_host, db_port):
    if not os.path.isfile(sql_script):
        print(f"Le fichier {sql_script} n'existe pas.")
        sys.exit(1)

    password = getpass.getpass(f"Enter the password for the PostgreSQL user {db_user}: ")

    # Connexion à la base de données
    try:
        conn = psycopg2.connect(
            dbname=db_name,
            user=db_user,
            password=password,
            host=db_host,
            port=db_port
        )
    except psycopg2.Error as e:
        print(f"Erreur de connexion à la base de données: {e}")
        sys.exit(1)

    # Lecture et exécution du script SQL
    try:
        with conn.cursor() as cursor, open(sql_script, 'r') as file:
            sql = file.read()
            cursor.execute(sql)
            conn.commit()
            print(f"Le script SQL {sql_script} a été exécuté avec succès.")
    except Exception as e:
        print(f"Erreur lors de l'exécution du script SQL: {e}")
        conn.rollback()
    finally:
        conn.close()

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <SQL_SCRIPT>")
        sys.exit(1)

    sql_script = sys.argv[1]
    db_user = 'dst_designer'
    db_name = 'dst_airlines_db'
    db_host = 'localhost'  # Hôte pour le conteneur Docker
    db_port = 6432         # Port mappé pour PostgreSQL dans le conteneur Docker

    execute_sql_script(sql_script, db_user, db_name, db_host, db_port)

if __name__ == "__main__":
    main()
