#!/bin/sh
#docker run -d -ti --rm -p 8080:8080 --network host rest-crud-quarkus-native $@
docker run --cpuset-cpus=0-3 --cpuset-mems=0 -d --rm -p 8080:8080 --network host rest-crud-quarkus-native
