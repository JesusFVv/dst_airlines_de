#!/bin/bash

# Vérification des droits d'administration
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté avec des privilèges administrateur (sudo)."
   exit 1
fi

# Mise à jour des paquets et installation des dépendances pour PostgreSQL et Python
echo "Mise à jour des paquets..."
apt-get update -y

echo "Installation de pip et des paquets Python nécessaires..."
apt-get install -y python3-pip

# Installer les bibliothèques Python nécessaires
pip3 install psycopg2-binary py7zr


# Vérification de l'installation de pip
echo "Vérification de l'installation de pip..."
if ! command -v pip3 > /dev/null; then
    echo "pip3 n'a pas été installé correctement."
    exit 1
fi

# Afficher les versions des outils installés

echo "Version de Python:"
python3 --version

echo "Version de pip:"
pip3 --version

echo "Installation des dépendances Python:"
pip3 list | grep -E 'psycopg2-binary|py7zr'

echo "Toutes les dépendances ont été installées avec succès."
