#!/bin/sh

export MMAP_TRACE="mmap_trace.txt"
export ALLOCATION_TRACE="alloc_trace.txt"
export MALLOC_TRACE="malloc_trace.txt"
export OMRPORT_TRACE="true"
ulimit -c unlimited
# LD_PRELOAD=/work/libmmaptracker.so:/work/liballoctracker.so ${JAVA_HOME}/bin/java -Dquarkus.datasource.url="jdbc:postgresql://localhost:${DB_PORT}/rest-crud" -Dquarkus.http.port=${HTTP_PORT} -Xshareclasses:name=quarkus,cacheDir=/opt/.classCache,cacheDirPerm=1000,readonly -XX:ShareClassesEnableBCI -Xscmx25m -Xnoaot -Djava.net.preferIPv4Stack=true -cp /work/application -jar /work/application.jar

${JAVA_HOME}/bin/java -Dquarkus.datasource.url="jdbc:postgresql://localhost:${DB_PORT}/rest-crud" -Dquarkus.http.port=${HTTP_PORT} -Xshareclasses:name=quarkus,cacheDir=/opt/.classCache,cacheDirPerm=1000,readonly -Xscmx150M -Xscmaxaot120m -Xtune:virtualized -XX:ShareClassesEnableBCI -Djava.net.preferIPv4Stack=true -cp /work/application -jar /work/application.jar

# ${JAVA_HOME}/bin/java -Xshareclasses:none -Dquarkus.datasource.url="jdbc:postgresql://localhost:${DB_PORT}/rest-crud" -Dquarkus.http.port=${HTTP_PORT} -Djava.net.preferIPv4Stack=true -cp /work/application -jar /work/application.jar


