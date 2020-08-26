#!/bin/bash

ulimit -s 256
echo "Soft limits:"
ulimit -Sa
echo "Hard limits:"
ulimit -Ha
export ALLOCATION_TRACE="alloc_trace.txt"
export MMAP_TRACE="mmap_trace.txt"
#LD_PRELOAD=/work/libmmaptracker.so:/work/liballoctracker.so ./application -Dhttp.host=0.0.0.0 ${HEAP_SETTINGS} -Dquarkus.datasource.url="jdbc:postgresql://localhost:${DB_PORT}/rest-crud" -Dquarkus.http.port=${HTTP_PORT}
./application -Dhttp.host=0.0.0.0 ${HEAP_SETTINGS} -Dquarkus.datasource.url="jdbc:postgresql://localhost:${DB_PORT}/rest-crud" -Dquarkus.http.port=${HTTP_PORT}

#LD_PRELOAD=/work/libmmaptracker.so:/work/liballoctracker.so ./application -Dhttp.host=0.0.0.0 -Xmx128m -Dquarkus.datasource.url="jdbc:postgresql://localhost:${DB_PORT}/rest-crud" -Dquarkus.http.port=${HTTP_PORT}
