#!/bin/bash

list="128"

JAVA_HOME="/home/ashutosh/builds/openj9/jdk8u232-b09"

if [ $# -ne 1 ]; then
	echo "Insufficient arguments"
	exit -1;
fi

type=$1

if [ -z "${type}" ]; then
	type="native" # default type
fi

function start_run_fixed_heap
{
	log_dir=$1
	itr=$2
	size=$3
	echo "LOG_DIR: ${log_dir}"
	echo "Starting server for fixed heap size=${size}m, iteration=${itr}"
	
	if [ "$type" = "openj9" ]; then
		numactl --physcpubind="0,1,32,33" --membind="0" ${JAVA_HOME}/bin/java -Xverbosegclog:${log_dir}/gc.log.${itr} -Dquarkus.http.port=9090 -Xshareclasses:name=quarkus,cacheDir=/home/ashutosh/quarkusRestCrudDemo/quarkus/.classCache,cacheDirPerm=1000,readonly -XX:ShareClassesEnableBCI -Xscmx25m -Xnoaot -Xms${size}m -Xmx${size}m -Djava.net.preferIPv4Stack=true -cp target -jar target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner.jar &
		sleep 10s
	else
		nursery=$(( size * 90 / 100 ))
		initial=$(( size * 80 / 100 ))
		echo "Running with -Xms${initial}m Xmn${nursery}m -Xmx${size}m"
		# numactl --physcpubind="0,1,32,33" --membind="0" target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner -Xms${size}m -Xmx${size}m -Xmn${nursery}m -Dquarkus.http.port=9090 &
		target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner -Xms${initial}m -Xmx${size}m -Xmn${nursery}m -Dquarkus.http.port=9090 &
		sleep 5s
	fi

	if [ "$type" = "openj9" ]; then
		pid=`ps -ef | grep java | grep -v grep | awk '{ print $2 }'`
	else
		pid=`ps -ef | grep rest-http-crud-quarkus | grep -v grep | awk '{ print $2 }'`
	fi
	echo "Server pid: ${pid}"

	./run_top.sh ${pid} &> ${log_dir}/top.cold.${itr}.out &
	top_pid=`ps -ef | grep "top -b" | grep -v grep | awk '{ print $2 }'`
	echo "Starting load for cold run ..."
	numactl --physcpubind="18,19" --membind="1" ./wrk --threads=40 --connections=40 -d60s http://127.0.0.1:9090/fruits &>${log_dir}/cold.${itr}
	kill -9 ${top_pid}

	./run_top.sh ${pid} &> ${log_dir}/top.warm.${itr}.1.out &
	top_pid=`ps -ef | grep "top -b" | grep -v grep | awk '{ print $2 }'`
	echo "Starting load for warm run 1 ..."
	numactl --physcpubind="18,19" --membind="1" ./wrk --threads=40 --connections=40 -d60s http://127.0.0.1:9090/fruits &>${log_dir}/warm.${itr}
	kill -9 ${top_pid}

	./run_top.sh ${pid} &> ${log_dir}/top.warm.${itr}.2.out &
	top_pid=`ps -ef | grep "top -b" | grep -v grep | awk '{ print $2 }'`
	echo "Starting load for warm run 2 ..."
	numactl --physcpubind="18,19" --membind="1" ./wrk --threads=40 --connections=40 -d60s http://127.0.0.1:9090/fruits &>>${log_dir}/warm.${itr}
	kill -9 ${top_pid}

	pmap -X ${pid} &> ${log_dir}/pmap.${itr}.out
	kill -9 ${pid}

	avgcpu=`grep "${pid}" ${log_dir}/top.warm.${itr}* | grep rest | cut -d ':' -f 2 | awk 'BEGIN{sum=0}{sum+=$9}END{print sum/NR}'`
	echo "iteration${itr} ${avgcpu}" >> ${log_dir}/cpu
	rss=`tail -n 1 ${log_dir}/pmap.${itr}.out | awk '{print $2}'`
	echo "iteration${itr} ${rss}" >> ${log_dir}/rss
}

summarize_results()
{
	log_dir=$1
	pushd $log_dir
	avg_thrput=`grep "Requests" warm* | awk 'BEGIN{sum=0}{sum+=$2}END{print sum/NR}'`
	avg_cpu=`cat cpu | awk 'BEGIN{sum=0}{sum+=$2}END{print sum/NR}'`
	avg=`echo $avg | awk '{ print $1 / 4 }'` # normalize to 1 cpu
	avg_rss=`cat rss | awk 'BEGIN{sum=0}{sum+=$2}END{print sum/NR}'`
	echo "Avg Throughput: ${avg_thrput}" > results
	echo "Avg CPU: ${avg_cpu}" >> results
	echo "Avg RSS: ${avg_rss} KB" >> results
	popd
}

for size in ${list}; do
	LOG_DIR="$type/logs_fixed_heap_size_${size}"
	mkdir -p ${LOG_DIR}
done

if [ "$type" = "openj9" ]; then
	echo "Delete any existing scc..."
	${JAVA_HOME}/bin/java -Xshareclasses:name=quarkus,cacheDir=/home/ashutosh/quarkusRestCrudDemo/quarkus/.classCache,cacheDirPerm=1000,destroy

	echo "Creating new scc..."
	${JAVA_HOME}/bin/java -Dquarkus.http.port=9090 -Xshareclasses:name=quarkus,cacheDir=/home/ashutosh/quarkusRestCrudDemo/quarkus/.classCache,cacheDirPerm=1000 -XX:ShareClassesEnableBCI -Xscmx25m -Xnoaot -Xmx128m -Djava.net.preferIPv4Stack=true -cp target -jar target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner.jar &

	sleep 10s

	pid=`ps -ef| grep java | grep -v grep | awk '{ print $2 }'`
	echo "Generate load..."
	./wrk --threads=40 --connections=40 -d60s http://127.0.0.1:9090/fruits | tee cold_scc.out
	kill -9 "${pid}"
fi

for itr in `seq 1 1`; do
	for size in ${list}; do
		LOG_DIR="$type/logs_fixed_heap_size_${size}"
		start_run_fixed_heap "${LOG_DIR}" "${itr}" "${size}"
	done
done

for size in ${list}; do
	LOG_DIR="$type/logs_fixed_heap_size_${size}"
	summarize_results "${LOG_DIR}" 
done
