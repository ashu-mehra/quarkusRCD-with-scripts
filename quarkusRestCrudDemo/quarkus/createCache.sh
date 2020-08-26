#!/bin/sh
#-Xshareclasses:name=quarkus-1,cacheDir=.classCache,cacheDirPerm=1000 -XX:ShareClassesEnableBCI -Xscmx80m
#-XX:-StackTraceInThrowable -Xverify:none
#-Dquarkus.http.host=192.168.90.176
${JAVA_HOME}/bin/java -Dquarkus.http.port=8080 -Xshareclasses:name=quarkus,cacheDir=/opt/.classCache,cacheDirPerm=1000 -XX:ShareClassesEnableBCI -Xscmx150M -Xscmaxaot120m -Xtune:virtualized -Xmx128m -Djava.net.preferIPv4Stack=true -cp /work/application -jar /work/application.jar &
sleep 10s
echo "Starting load..."
./wrk --threads=40 --connections=40 -d60s http://127.0.0.1:8080/fruits
./wrk --threads=40 --connections=40 -d60s http://127.0.0.1:8080/fruits
#java -Xshareclasses:name=quarkus,cacheDir=/tmp/.classCache,cacheDirPerm=1000 -XX:ShareClassesEnableBCI -Xscmx80m -Xmx128m -Djava.net.preferIPv4Stack=true -cp ./target -jar ./target/pingperf-runner.jar 
