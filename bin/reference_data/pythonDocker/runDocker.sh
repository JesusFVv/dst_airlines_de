#!/bin/bash

# run
docker run -d \
  --volume $(pwd)/python_reference_data:/app/output \
  --name python_app_reference_data \
  python_reference_data

