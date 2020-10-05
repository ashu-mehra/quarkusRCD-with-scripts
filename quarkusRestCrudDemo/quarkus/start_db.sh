#!/bin/bash

DB_CONTAINER_NAME="postgres-quarkus-rest-http-crud"

sudo docker run --network=host -d --cpuset-cpus=0,1,4,5 --cpuset-mems=0 --ulimit memlock=-1:-1 -it --memory-swappiness=0 --name ${DB_CONTAINER_NAME} -e POSTGRES_USER=restcrud -e POSTGRES_PASSWORD=restcrud -e POSTGRES_DB=rest-crud -p 5432:5432 postgres:10.5
