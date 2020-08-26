#!/bin/sh

export MMAP_TRACE="mmap_trace.txt"
export ALLOCATION_TRACE="alloc_trace.txt"
export MALLOC_TRACE="malloc_trace.txt"
export OMRPORT_TRACE="true"
ulimit -c unlimited

${JAVA_HOME}/bin/java -Dquarkus.datasource.url="jdbc:postgresql://localhost:${DB_PORT}/rest-crud" -Dquarkus.http.port=${HTTP_PORT} -Djava.net.preferIPv4Stack=true -cp /work/application -jar /work/application.jar

# ${JAVA_HOME}/bin/java -Dquarkus.datasource.url="jdbc:postgresql://localhost:${DB_PORT}/rest-crud" -Dquarkus.http.port=${HTTP_PORT} -Djava.net.preferIPv4Stack=true -cp /work/application -jar /work/application.jar

