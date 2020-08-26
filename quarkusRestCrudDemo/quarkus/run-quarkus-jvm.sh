#!/bin/sh
#docker run -ti --rm -p 8080:8080 --network host rest-crud-quarkus-jvm
docker run --cpuset-cpus=0-3 --cpuset-mems=0 --env-file=java.env --init -d --rm -p 8080:8080 --network host rest-crud-quarkus-jvm-scc-noaot-readonly
