# Utiliser une image de base Jupyter avec Python
FROM jupyter/base-notebook:latest

# Installation des dépendances pour PostgreSQL
RUN pip install --no-cache-dir psycopg2-binary pandas sqlalchemy

# Exposer le port Jupyter par défaut
EXPOSE 8346

# Création d’un dossier pour les notebooks (monté en volume plus tard)
RUN mkdir /home/jovyan/dst_airlines_de

# Démarrage de Jupyter Lab par défaut
CMD ["start.sh", "jupyter", "lab", "--LabApp.token=''", "--LabApp.allow_origin='*'", "--port=8346", "--no-browser", "--ip=0.0.0.0", "--notebook-dir=/home/jovyan/dst_airlines_de"]

