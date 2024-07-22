#!/bin/bash

# prepare build context
cp ../ingestRefData_01_referenceDataRaw.sql .
cp ../../common/runSqlScript.py .
cp ../../common/utils.py .
cp ../../common/database.ini .

# build
docker build -t python_reference_data .

# clean
rm ./ingestRefData_01_referenceDataRaw.sql
rm ./runSqlScript.py
rm ./utils.py
rm ./database.ini

