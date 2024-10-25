# Steps pour populer les tables
 
1. cd lib/reference_data/full_ingest

./create_docker_image.sh
./launch_docker_container.sh
 
2. cd lib/customer_flight_info/l1_loading

./build_docker_image.sh
./run_docker_container.sh
 
3. cd lib/customer_flight_info/l2_loading

./build_docker_image.sh
./run_docker_container.sh
 
