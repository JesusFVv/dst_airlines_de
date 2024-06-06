# Exécution V 2

 - Date : 27 Mai 2024
 - Remarque : la récupération du token n'est pas automatique
   - https://developer.lufthansa.com/io-docs

## Airports

```shell
cd /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/
mkdir outAirports
# Nombre d'aeroports : 11829
# Nombre de pages : 11829 / 100 = 119
# Récupération de tous les aéroports :
./loopRequest.sh -v -S 100 -T 2200 -R 118 -L Airports \
 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR\&LHoperated=0 \
 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR\&LHoperated=1 \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/outAirports/ \
 -H "Authorization: Bearer xwvqzy46tjb9ym32d5g53hs3"

```

## Countries

```shell
cd /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/
mkdir outCountries
# Nombre de pays : 238
# Nombre de pages : 238 / 100 = 3
# Récupération de tous les pays :
./loopRequest.sh -v -S 100 -T 2500 -R 2 -L Countries \
 -U https://api.lufthansa.com/v1/mds-references/countries/?lang=FR \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/outCountries/ \
 -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"

```

## Airlines

```shell
cd /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/
mkdir outAirlines
# Nombre de compagnies : 1132
# Nombre de pages : 1132 / 100 = 12
# Récupération de toutes les compagnies :
./loopRequest.sh -v -S 100 -T 2500 -R 11 -L Airlines \
 -U https://api.lufthansa.com/v1/mds-references/airlines/ \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/outAirlines/ \
 -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"

```


## Aircraft

```shell
cd /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/
mkdir outAircraft
# Nombre de modèles d'avions : 382
# Nombre de pages : 382 / 100 = 4
# Récupération de tous les modèles d'avions :
./loopRequest.sh -v -S 100 -T 2500 -R 3 -L Aircraft \
 -U https://api.lufthansa.com/v1/mds-references/aircraft/ \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/outAircraft/ \
 -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"

```

## Cities

```shell
cd /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/
mkdir outCities
# Nombre de modèles d'avions : 10688
# Nombre de pages : 10688 / 100 = 107
# Récupération de tous les modèles d'avions :
./loopRequest.sh -v -S 100 -T 2500 -R 106 -L Cities \
 -U https://api.lufthansa.com/v1/mds-references/cities/?lang=FR \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/outCities/ \
 -H "Authorization: Bearer k3nv9ys2uc9evkzd9vxwafe7"

```


## Test dichotomie sur un petit échantillon

```shell
./loopRequest.sh -v -S 10 -T 2000 -R 0 -L Airports \
 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR\&LHoperated=0 \
 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR\&LHoperated=1 \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ \
 -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd" \
 -I 535
```

```shell
Options :
	Mode verbose : oui
Entree :
	Endpoint : Airports
	URL : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0
	Pas : 10
	Premiere requete : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=10&offset=536
	Nombre de requetes : 1
	Index de départ: 536
	Index de fin : 545
	Temporisation : 00:00:02
	Estimation de la duree totale d'execution : 00:00:00
	Date estimée de fin d'exécution : 2024-05-28 00:10:38
Sortie :
	Repertoire de sortie : /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/
	Fichier de sauvegarde premiere page : Airports_200_536_to_545_T0_p1_1_20240528_001038.json
	Format : json
1 / 1 : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=10&offset=536
curl -s -o "/home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/Airports_200_536_to_545_T0_p1_1_20240528_001038_TMP.json" -w "%{http_code}" -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"  -k "https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=10&offset=536"
Ajout reprise sur erreur suite à code 500 lors de la tentative T0_p1_1 : "DICHO1"
Ajout reprise sur erreur suite à code 500 lors de la tentative T0_p1_1 : "DICHO2"
 - 500 -> Airports_500_536_to_545_T0_p1_1_20240528_001038.json
Date de démarrage du script : 2024-05-28 00:10:38
Date de fin : 2024-05-28 00:10:39
Délais : 00:00:01.317
Nombre de requêtes réalisées : 1 / 1
  500 : 1
Reprise sur erreur automatique T0 #1 / 2: "DICHO1", options=23 :
./loopRequest.sh -C 1 -S 5 -T 2000 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1 -I 535 -v -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ -L Airports -F json -P 3 -R 0 -H Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd
sleep 00:00:02.000
Options :
	Mode verbose : oui
Entree :
	Endpoint : Airports
	URL : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0
	Pas : 5
	Premiere requete : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=5&offset=536
	Nombre de requetes : 1
	Index de départ: 536
	Index de fin : 540
	Niveau de recursivité : 1
	Temporisation : 00:00:02
	Estimation de la duree totale d'execution : 00:00:00
	Date estimée de fin d'exécution : 2024-05-28 00:10:41
Sortie :
	Repertoire de sortie : /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/
	Fichier de sauvegarde premiere page : Airports_200_536_to_540_T1_p1_1_20240528_001041.json
	Format : json
1 / 1 : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=5&offset=536
curl -s -o "/home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/Airports_200_536_to_540_T1_p1_1_20240528_001041_TMP.json" -w "%{http_code}" -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"  -k "https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=5&offset=536"
Ajout reprise sur erreur suite à code 500 lors de la tentative T1_p1_1 : "DICHO1"
Ajout reprise sur erreur suite à code 500 lors de la tentative T1_p1_1 : "DICHO2"
 - 500 -> Airports_500_536_to_540_T1_p1_1_20240528_001041.json
Date de démarrage du script : 2024-05-28 00:10:41
Date de fin : 2024-05-28 00:10:42
Délais : 00:00:01.190
Nombre de requêtes réalisées : 1 / 1
  500 : 1
Reprise sur erreur automatique T1 #1 / 2: "DICHO1", options=23 :
./loopRequest.sh -C 2 -S 2 -T 2000 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1 -I 535 -v -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ -L Airports -F json -P 3 -R 0 -H Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd
sleep 00:00:02.500
Options :
	Mode verbose : oui
Entree :
	Endpoint : Airports
	URL : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0
	Pas : 2
	Premiere requete : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=2&offset=536
	Nombre de requetes : 1
	Index de départ: 536
	Index de fin : 537
	Niveau de recursivité : 2
	Temporisation : 00:00:02
	Estimation de la duree totale d'execution : 00:00:00
	Date estimée de fin d'exécution : 2024-05-28 00:10:45
Sortie :
	Repertoire de sortie : /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/
	Fichier de sauvegarde premiere page : Airports_200_536_to_537_T2_p1_1_20240528_001045.json
	Format : json
1 / 1 : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=2&offset=536
curl -s -o "/home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/Airports_200_536_to_537_T2_p1_1_20240528_001045_TMP.json" -w "%{http_code}" -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"  -k "https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=2&offset=536"
 - 200 -> Airports_200_536_to_537_T2_p1_1_20240528_001045.json
Date de démarrage du script : 2024-05-28 00:10:45
Date de fin : 2024-05-28 00:10:46
Délais : 00:00:00.596
Nombre de requêtes réalisées : 1 / 1
  200 : 1
Reprise sur erreur automatique T1 #2 / 2: "DICHO2", options=23 :
./loopRequest.sh -C 2 -S 3 -T 2000 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1 -I 537 -v -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ -L Airports -F json -P 3 -R 0 -H Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd
sleep 00:00:02.500
Options :
	Mode verbose : oui
Entree :
	Endpoint : Airports
	URL : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0
	Pas : 3
	Premiere requete : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=3&offset=538
	Nombre de requetes : 1
	Index de départ: 538
	Index de fin : 540
	Niveau de recursivité : 2
	Temporisation : 00:00:02
	Estimation de la duree totale d'execution : 00:00:00
	Date estimée de fin d'exécution : 2024-05-28 00:10:48
Sortie :
	Repertoire de sortie : /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/
	Fichier de sauvegarde premiere page : Airports_200_538_to_540_T2_p1_1_20240528_001048.json
	Format : json
1 / 1 : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=3&offset=538
curl -s -o "/home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/Airports_200_538_to_540_T2_p1_1_20240528_001048_TMP.json" -w "%{http_code}" -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"  -k "https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=3&offset=538"
Ajout reprise sur erreur suite à code 500 lors de la tentative T2_p1_1 : "DICHO1"
Ajout reprise sur erreur suite à code 500 lors de la tentative T2_p1_1 : "DICHO2"
 - 500 -> Airports_500_538_to_540_T2_p1_1_20240528_001048.json
Date de démarrage du script : 2024-05-28 00:10:48
Date de fin : 2024-05-28 00:10:49
Délais : 00:00:00.681
Nombre de requêtes réalisées : 1 / 1
  500 : 1
Reprise sur erreur automatique T2 #1 / 2: "DICHO1", options=23 :
./loopRequest.sh -C 3 -S 1 -T 2000 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1 -I 537 -v -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ -L Airports -F json -P 3 -R 0 -H Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd
sleep 00:00:03.000
Options :
	Mode verbose : oui
Entree :
	Endpoint : Airports
	URL : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0
	Pas : 1
	Premiere requete : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=538
	Nombre de requetes : 1
	Index de départ: 538
	Index de fin : 538
	Niveau de recursivité : 3
	Temporisation : 00:00:02
	Estimation de la duree totale d'execution : 00:00:00
	Date estimée de fin d'exécution : 2024-05-28 00:10:52
Sortie :
	Repertoire de sortie : /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/
	Fichier de sauvegarde premiere page : Airports_200_538_to_538_T3_p1_1_20240528_001052.json
	Format : json
1 / 1 : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=538
curl -s -o "/home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/Airports_200_538_to_538_T3_p1_1_20240528_001052_TMP.json" -w "%{http_code}" -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"  -k "https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=538"
 - 200 -> Airports_200_538_to_538_T3_p1_1_20240528_001052.json
Date de démarrage du script : 2024-05-28 00:10:52
Date de fin : 2024-05-28 00:10:52
Délais : 00:00:00.112
Nombre de requêtes réalisées : 1 / 1
  200 : 1
Reprise sur erreur automatique T2 #2 / 2: "DICHO2", options=23 :
./loopRequest.sh -C 3 -S 2 -T 2000 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1 -I 538 -v -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ -L Airports -F json -P 3 -R 0 -H Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd
sleep 00:00:03.000
Options :
	Mode verbose : oui
Entree :
	Endpoint : Airports
	URL : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0
	Pas : 2
	Premiere requete : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=2&offset=539
	Nombre de requetes : 1
	Index de départ: 539
	Index de fin : 540
	Niveau de recursivité : 3
	Temporisation : 00:00:02
	Estimation de la duree totale d'execution : 00:00:00
	Date estimée de fin d'exécution : 2024-05-28 00:10:55
Sortie :
	Repertoire de sortie : /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/
	Fichier de sauvegarde premiere page : Airports_200_539_to_540_T3_p1_1_20240528_001055.json
	Format : json
1 / 1 : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=2&offset=539
curl -s -o "/home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/Airports_200_539_to_540_T3_p1_1_20240528_001055_TMP.json" -w "%{http_code}" -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"  -k "https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=2&offset=539"
Ajout reprise sur erreur suite à code 500 lors de la tentative T3_p1_1 : "DICHO1"
Ajout reprise sur erreur suite à code 500 lors de la tentative T3_p1_1 : "DICHO2"
 - 500 -> Airports_500_539_to_540_T3_p1_1_20240528_001055.json
Date de démarrage du script : 2024-05-28 00:10:55
Date de fin : 2024-05-28 00:10:56
Délais : 00:00:00.644
Nombre de requêtes réalisées : 1 / 1
  500 : 1
Reprise sur erreur automatique T3 #1 / 2: "DICHO1", options=23 :
./loopRequest.sh -C 4 -S 1 -T 2000 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1 -I 538 -v -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ -L Airports -F json -P 3 -R 0 -H Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd
sleep 00:00:03.500
Options :
	Mode verbose : oui
Entree :
	Endpoint : Airports
	URL : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0
	Pas : 1
	Premiere requete : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=539
	Nombre de requetes : 1
	Index de départ: 539
	Index de fin : 539
	Niveau de recursivité : 4
	Temporisation : 00:00:02
	Estimation de la duree totale d'execution : 00:00:00
	Date estimée de fin d'exécution : 2024-05-28 00:10:59
Sortie :
	Repertoire de sortie : /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/
	Fichier de sauvegarde premiere page : Airports_200_539_to_539_T4_p1_1_20240528_001059.json
	Format : json
1 / 1 : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=539
curl -s -o "/home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/Airports_200_539_to_539_T4_p1_1_20240528_001059_TMP.json" -w "%{http_code}" -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"  -k "https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=539"
 - 200 -> Airports_200_539_to_539_T4_p1_1_20240528_001059.json
Date de démarrage du script : 2024-05-28 00:10:59
Date de fin : 2024-05-28 00:10:59
Délais : 00:00:00.112
Nombre de requêtes réalisées : 1 / 1
  200 : 1
Reprise sur erreur automatique T3 #2 / 2: "DICHO2", options=23 :
./loopRequest.sh -C 4 -S 1 -T 2000 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1 -I 539 -v -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ -L Airports -F json -P 3 -R 0 -H Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd
sleep 00:00:03.500
Options :
	Mode verbose : oui
Entree :
	Endpoint : Airports
	URL : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0
	Pas : 1
	Premiere requete : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=540
	Nombre de requetes : 1
	Index de départ: 540
	Index de fin : 540
	Niveau de recursivité : 4
	Temporisation : 00:00:02
	Estimation de la duree totale d'execution : 00:00:00
	Date estimée de fin d'exécution : 2024-05-28 00:11:03
Sortie :
	Repertoire de sortie : /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/
	Fichier de sauvegarde premiere page : Airports_200_540_to_540_T4_p1_1_20240528_001103.json
	Format : json
1 / 1 : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=540
curl -s -o "/home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/Airports_200_540_to_540_T4_p1_1_20240528_001103_TMP.json" -w "%{http_code}" -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"  -k "https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=540"
Ajout reprise sur erreur suite à code 500 lors de la tentative T4_p1_1 : "RETRY"
 - 500 -> Airports_500_540_to_540_T4_p1_1_20240528_001103.json
Date de démarrage du script : 2024-05-28 00:11:03
Date de fin : 2024-05-28 00:11:03
Délais : 00:00:00.625
Nombre de requêtes réalisées : 1 / 1
  500 : 1
Reprise sur erreur automatique T4 #1 / 1: "RETRY", options=21 :
./loopRequest.sh -C 5 -S 1 -I 539 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1 -v -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ -L Airports -F json -P 3 -R 0 -H Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd
sleep 00:00:04.000
Options :
	Mode verbose : oui
Entree :
	Endpoint : Airports
	URL : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0
	Pas : 1
	Premiere requete : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=540
	Nombre de requetes : 1
	Index de départ: 540
	Index de fin : 540
	Niveau de recursivité : 5
	Temporisation : 00:00:01
	Estimation de la duree totale d'execution : 00:00:00
	Date estimée de fin d'exécution : 2024-05-28 00:11:08
Sortie :
	Repertoire de sortie : /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/
	Fichier de sauvegarde premiere page : Airports_200_540_to_540_T5_p1_1_20240528_001108.json
	Format : json
1 / 1 : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=540
curl -s -o "/home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/Airports_200_540_to_540_T5_p1_1_20240528_001108_TMP.json" -w "%{http_code}" -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"  -k "https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=1&offset=540"
Ajout reprise sur erreur suite à code 500 lors de la tentative T5_p1_1 : "RETRY_BACKUP"
 - 500 -> Airports_500_540_to_540_T5_p1_1_20240528_001108.json
Date de démarrage du script : 2024-05-28 00:11:08
Date de fin : 2024-05-28 00:11:08
Délais : 00:00:00.533
Nombre de requêtes réalisées : 1 / 1
  500 : 1
Reprise sur erreur automatique T5 #1 / 1: "RETRY_BACKUP", options=21 :
./loopRequest.sh -C 6 -S 1 -I 539 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0 -v -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ -L Airports -F json -P 3 -R 0 -H Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd
sleep 00:00:03.500
Options :
	Mode verbose : oui
Entree :
	Endpoint : Airports
	URL : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1
	Pas : 1
	Premiere requete : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1&limit=1&offset=540
	Nombre de requetes : 1
	Index de départ: 540
	Index de fin : 540
	Niveau de recursivité : 6
	Temporisation : 00:00:01
	Estimation de la duree totale d'execution : 00:00:00
	Date estimée de fin d'exécution : 2024-05-28 00:11:12
Sortie :
	Repertoire de sortie : /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/
	Fichier de sauvegarde premiere page : Airports_200_540_to_540_T6_p1_1_20240528_001112.json
	Format : json
1 / 1 : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1&limit=1&offset=540
curl -s -o "/home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/Airports_200_540_to_540_T6_p1_1_20240528_001112_TMP.json" -w "%{http_code}" -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"  -k "https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1&limit=1&offset=540"
 - 200 -> Airports_200_540_to_540_T6_p1_1_20240528_001112.json
Date de démarrage du script : 2024-05-28 00:11:12
Date de fin : 2024-05-28 00:11:12
Délais : 00:00:00.112
Nombre de requêtes réalisées : 1 / 1
  200 : 1
Reprise sur erreur automatique T0 #2 / 2: "DICHO2", options=23 :
./loopRequest.sh -C 1 -S 5 -T 2000 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=1 -I 540 -v -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ -L Airports -F json -P 3 -R 0 -H Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd
sleep 00:00:02.000
Options :
	Mode verbose : oui
Entree :
	Endpoint : Airports
	URL : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0
	Pas : 5
	Premiere requete : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=5&offset=541
	Nombre de requetes : 1
	Index de départ: 541
	Index de fin : 545
	Niveau de recursivité : 1
	Temporisation : 00:00:02
	Estimation de la duree totale d'execution : 00:00:00
	Date estimée de fin d'exécution : 2024-05-28 00:11:14
Sortie :
	Repertoire de sortie : /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/
	Fichier de sauvegarde premiere page : Airports_200_541_to_545_T1_p1_1_20240528_001114.json
	Format : json
1 / 1 : https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=5&offset=541
curl -s -o "/home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/Airports_200_541_to_545_T1_p1_1_20240528_001114_TMP.json" -w "%{http_code}" -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd"  -k "https://api.lufthansa.com/v1/mds-references/airports/?lang=FR&LHoperated=0&limit=5&offset=541"
 - 200 -> Airports_200_541_to_545_T1_p1_1_20240528_001114.json
Date de démarrage du script : 2024-05-28 00:11:14
Date de fin : 2024-05-28 00:11:15
Délais : 00:00:00.775
Nombre de requêtes réalisées : 1 / 1
  200 : 1
```

```shell
ls -lah out
total 28K
drwxrwxrwx 1 root root  632 mai   28 00:11 .
drwxrwxrwx 1 root root 4,0K mai   27 23:26 ..
-rwxrwxrwx 1 root root 1,4K mai   28 00:10 Airports_200_536_to_537_T2_p1_1_20240528_001045.json
-rwxrwxrwx 1 root root 1,2K mai   28 00:10 Airports_200_538_to_538_T3_p1_1_20240528_001052.json
-rwxrwxrwx 1 root root 1,2K mai   28 00:10 Airports_200_539_to_539_T4_p1_1_20240528_001059.json
-rwxrwxrwx 1 root root 1,2K mai   28 00:11 Airports_200_540_to_540_T6_p1_1_20240528_001112.json
-rwxrwxrwx 1 root root 2,2K mai   28 00:11 Airports_200_541_to_545_T1_p1_1_20240528_001114.json
-rwxrwxrwx 1 root root  274 mai   28 00:10 Airports_500_536_to_540_T1_p1_1_20240528_001041.json
-rwxrwxrwx 1 root root  274 mai   28 00:10 Airports_500_536_to_545_T0_p1_1_20240528_001038.json
-rwxrwxrwx 1 root root  274 mai   28 00:10 Airports_500_538_to_540_T2_p1_1_20240528_001048.json
-rwxrwxrwx 1 root root  274 mai   28 00:10 Airports_500_539_to_540_T3_p1_1_20240528_001055.json
-rwxrwxrwx 1 root root  274 mai   28 00:11 Airports_500_540_to_540_T4_p1_1_20240528_001103.json
-rwxrwxrwx 1 root root  274 mai   28 00:11 Airports_500_540_to_540_T5_p1_1_20240528_001108.json
```

## Test dichotomie sur un échantillon de 100

```shell
./loopRequest.sh -v -S 100 -T 2000 -R 0 -L Airports \
 -U https://api.lufthansa.com/v1/mds-references/airports/?lang=FR\&LHoperated=0 \
 -B https://api.lufthansa.com/v1/mds-references/airports/?lang=FR\&LHoperated=1 \
 -O /home/christophe/Documents/data_ntfs/Projets/formations/dataing/projet/dev/out/ \
 -H "Authorization: Bearer urscpj2vmdgkjyvbtq4nrjfd" \
 -I 500
 
```
Sur cet échantillon de 100 on a deux erreurs :
 - Erreur 500 à l'offset 540
 - Erreur 404 à l'offset 559

On passe de 100 call avant la stratégie dichotomie à 29.
Pour une plage de 100 qui ne contient qu'une seule erreur, on passerait à environ 16 calls au lieu de 100

```shell
ls -lah out
total 80K
drwxrwxrwx 1 root root  256 mai   28 00:29 .
drwxrwxrwx 1 root root 4,0K mai   27 23:26 ..
-rwxrwxrwx 1 root root 7,3K mai   28 00:27 Airports_200_501_to_525_T2_p1_1_20240528_002743.json
-rwxrwxrwx 1 root root 3,9K mai   28 00:27 Airports_200_526_to_537_T3_p1_1_20240528_002751.json
-rwxrwxrwx 1 root root 1,2K mai   28 00:28 Airports_200_538_to_538_T6_p1_1_20240528_002809.json
-rwxrwxrwx 1 root root 1,2K mai   28 00:28 Airports_200_539_to_539_T7_p1_1_20240528_002820.json
-rwxrwxrwx 1 root root 1,2K mai   28 00:28 Airports_200_540_to_540_T8_p1_1_20240528_002831.json
-rwxrwxrwx 1 root root 1,7K mai   28 00:28 Airports_200_541_to_543_T5_p1_1_20240528_002835.json
-rwxrwxrwx 1 root root 2,7K mai   28 00:28 Airports_200_544_to_550_T4_p1_1_20240528_002839.json
-rwxrwxrwx 1 root root 2,5K mai   28 00:28 Airports_200_551_to_556_T4_p1_1_20240528_002854.json
-rwxrwxrwx 1 root root 1,2K mai   28 00:29 Airports_200_557_to_557_T6_p1_1_20240528_002909.json
-rwxrwxrwx 1 root root 1,2K mai   28 00:29 Airports_200_558_to_558_T7_p1_1_20240528_002919.json
-rwxrwxrwx 1 root root 1,2K mai   28 00:29 Airports_200_559_to_559_T8_p1_1_20240528_002930.json
-rwxrwxrwx 1 root root 1,7K mai   28 00:29 Airports_200_560_to_562_T5_p1_1_20240528_002934.json
-rwxrwxrwx 1 root root 4,2K mai   28 00:29 Airports_200_563_to_575_T3_p1_1_20240528_002938.json
-rwxrwxrwx 1 root root 7,2K mai   28 00:29 Airports_200_576_to_600_T2_p1_1_20240528_002942.json
-rwxrwxrwx 1 root root  298 mai   28 00:28 Airports_404_551_to_562_T3_p1_1_20240528_002850.json
-rwxrwxrwx 1 root root  298 mai   28 00:28 Airports_404_551_to_575_T2_p1_1_20240528_002846.json
-rwxrwxrwx 1 root root  298 mai   28 00:28 Airports_404_551_to_600_T1_p1_1_20240528_002842.json
-rwxrwxrwx 1 root root  298 mai   28 00:29 Airports_404_557_to_559_T5_p1_1_20240528_002904.json
-rwxrwxrwx 1 root root  298 mai   28 00:28 Airports_404_557_to_562_T4_p1_1_20240528_002859.json
-rwxrwxrwx 1 root root  298 mai   28 00:29 Airports_404_558_to_559_T6_p1_1_20240528_002913.json
-rwxrwxrwx 1 root root  298 mai   28 00:29 Airports_404_559_to_559_T7_p1_1_20240528_002924.json
-rwxrwxrwx 1 root root  274 mai   28 00:27 Airports_500_501_to_550_T1_p1_1_20240528_002738.json
-rwxrwxrwx 1 root root  274 mai   28 00:27 Airports_500_501_to_600_T0_p1_1_20240528_002732.json
-rwxrwxrwx 1 root root  274 mai   28 00:27 Airports_500_526_to_550_T2_p1_1_20240528_002747.json
-rwxrwxrwx 1 root root  274 mai   28 00:28 Airports_500_538_to_540_T5_p1_1_20240528_002804.json
-rwxrwxrwx 1 root root  274 mai   28 00:28 Airports_500_538_to_543_T4_p1_1_20240528_002759.json
-rwxrwxrwx 1 root root  274 mai   28 00:27 Airports_500_538_to_550_T3_p1_1_20240528_002755.json
-rwxrwxrwx 1 root root  274 mai   28 00:28 Airports_500_539_to_540_T6_p1_1_20240528_002814.json
-rwxrwxrwx 1 root root  274 mai   28 00:28 Airports_500_540_to_540_T7_p1_1_20240528_002825.json
```

### Stats dichotomie

#### Cities

 - Nombre de villes : 10688
 - Nombre de calls minimum : 107
 - Nombre de villes en erreur : 23

|       | Sans erreur | dichotomie | sans dichotomie |
|-------|-------------|------------|-----------------|
| calls |         107 |        510 |            2430 |
| Durée |  10 minutes | 47 minutes |            3h45 |

#### Airports

 - Nombre d'aéroports : 11829
 - Nombre de calls minimum : 119
 - Nombre d'aéroports en erreur récupérées : 12
 - Nombre d'aéroports en erreur non récupérées : 52

|       | Sans erreur | dichotomie | sans dichotomie |
|-------|-------------|------------|-----------------|
| calls |         119 |       1135 |            6519 |
| Durée |  11 minutes |       1h42 |            9h45 |

