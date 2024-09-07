#!/bin/bash

# Parse options
while getopts ":i" option; do
    case $option in
        i) INIT_CONFIG="true";;
        \?) echo "Invalid option: -$OPTARG"; exit 1;;
    esac
done

# A - INIT ENV if -i option is specified
if [ "$INIT_CONFIG" = "true" ]; then
	sudo ./ingestRefData_00_initConfigure.sh
fi

# B - CLEAR AND INIT RAW TABLES
python3 ./common/runSqlScript.py ./ingestRefData_01_referenceDataRaw.sql ./common/database.ini

# C - INGEST RAW
python3 ./ingestRefData_02_ingestReferenceDataRaw.py ./common/database.ini /home/ubuntu/dst_airlines_de/data/referenceData
