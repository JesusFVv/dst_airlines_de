#!/bin/bash

# Parse options
while getopts ":il" option; do
    case $option in
        i) INIT_CONFIG="true";;
        l) LINK_COMMON="true";;
        \?) echo "Invalid option: -$OPTARG"; exit 1;;
    esac
done

# A - CREATE SYMBOLIC LINK IF -l OPTION IS SPECIFIED
if [ "$LINK_COMMON" = "true" ]; then
    if [ ! -e "./common" ]; then
        ln -s ../common ./common
        echo "Symbolic link to ../common created."
    else
        echo "Symbolic link to ../common already exists."
    fi
fi

# B - INIT ENV if -i option is specified
if [ "$INIT_CONFIG" = "true" ]; then
	sudo ./ingestRefData_00_initConfigure.sh
fi

# C - CLEAR AND INIT RAW TABLES
python3 ./common/runSqlScript.py ./ingestRefData_01_referenceDataRaw.sql ./common/database.ini

# D - INGEST RAW
python3 ./ingestRefData_02_ingestReferenceDataRaw.py ./common/database.ini /home/ubuntu/dst_airlines_de/data/referenceData
