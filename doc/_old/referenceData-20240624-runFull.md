# Exécution V 2

 - Date : 27 Mai 2024
 - Remarque : la récupération du token n'est pas automatique
   - https://developer.lufthansa.com/io-docs

## Airports

```shell
cd /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/
mkdir outEN_Airports
# Nombre d'aeroports : 11829
# Nombre de pages : 11829 / 100 = 119
# Récupération de tous les aéroports :
./loopRequest.sh -v -S 100 -T 2200 -R 118 -L Airports \
 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=EN\&LHoperated=0 \
 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=EN\&LHoperated=1 \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/outEN_Airports/ \
 -H "Authorization: Bearer cg8b49bhjytj9tqbgwzwbn4t"

```

## Countries

```shell
cd /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/
mkdir outEN_Countries
# Nombre de pays : 238
# Nombre de pages : 238 / 100 = 3
# Récupération de tous les pays :
./loopRequest.sh -v -S 100 -T 2500 -R 2 -L Countries \
 -U https://api.lufthansa.com/v1/mds-references/countries/?lang=EN \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/outEN_Countries/ \
 -H "Authorization: Bearer cg8b49bhjytj9tqbgwzwbn4t"

```

## Airlines

```shell
cd /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/
mkdir outEN_Airlines
# Nombre de compagnies : 1132
# Nombre de pages : 1132 / 100 = 12
# Récupération de toutes les compagnies :
./loopRequest.sh -v -S 100 -T 2500 -R 11 -L Airlines \
 -U https://api.lufthansa.com/v1/mds-references/airlines/ \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/outEN_Airlines/ \
 -H "Authorization: Bearer cg8b49bhjytj9tqbgwzwbn4t"

```


## Aircraft

```shell
cd /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/
mkdir outEN_Aircraft
# Nombre de modèles d'avions : 382
# Nombre de pages : 382 / 100 = 4
# Récupération de tous les modèles d'avions :
./loopRequest.sh -v -S 100 -T 2500 -R 3 -L Aircraft \
 -U https://api.lufthansa.com/v1/mds-references/aircraft/ \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/outEN_Aircraft/ \
 -H "Authorization: Bearer cg8b49bhjytj9tqbgwzwbn4t"

```

## Cities

```shell
cd /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/
mkdir outEN_Cities
# Nombre de villes : 10688
# Nombre de pages : 10688 / 100 = 107
# Récupération de toutes les villes :
./loopRequest.sh -v -S 100 -T 2500 -R 106 -L Cities \
 -U https://api.lufthansa.com/v1/mds-references/cities/?lang=EN \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/outEN_Cities/ \
 -H "Authorization: Bearer cg8b49bhjytj9tqbgwzwbn4t"

```
