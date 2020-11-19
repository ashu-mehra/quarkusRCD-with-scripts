#!/bin/bash

ulimit -c unlimited

function setDefaultConfig() {
	if [ -z "${JRE_HOME}" ]; then export JRE_HOME="${PWD}/jre"; fi
	if [ -z "${QUARKUS_REST_CRUD_APP}" ]; then export QUARKUS_REST_CRUD_APP="${PWD}"; fi
	if [ -z "${JARMIN_HOME}" ]; then export JARMIN_HOME="${PWD}/jarmin/"; fi
	if [ -z "${JAVA_HOME_FOR_QUARKUS}" ]; then export JAVA_HOME_FOR_QUARKUS="${PWD}/jdk-with-jarmin/j2re-image"; fi
	if [ -z "${JAVA_HOME_FOR_QUARKUS}" ]; then export JAVA_HOME_FOR_QUARKUS="${PWD}/jre"; fi
	if [ -z "${JARMIN_PHASE}" ]; then export JARMIN_PHASE="phase2"; fi # valid values: phase1 or phase2
	if [ -z "${DO_PERF_PROFILING}" ]; then export DO_PERF_PROFILING=0; fi
	if [ -z "${NUM_REQUESTS}" ]; then export NUM_REQUESTS=1; fi
	
	echo "Settings for this run:"
	echo "JRE_HOME: ${JRE_HOME}"
	echo "QUARKUS_REST_CRUD_APP: ${QUARKUS_REST_CRUD_APP}"
	echo "JARMIN_HOME: ${JARMIN_HOME}"
	echo "JAVA_HOME_FOR_QUARKUS:${JAVA_HOME_FOR_QUARKUS}"
	echo "RESULTS_DIR: ${RESULTS_DIR}"
	echo "-------------------"
}

function checkConfig() {
	if [ -z "${JRE_HOME}" ]; then echo "Error: JRE_HOME not set!"; exit -1; fi
	if [ -z "${QUARKUS_REST_CRUD_APP}" ]; then echo "Error: QUARKUS_REST_CRUD_APP not set!"; exit -1; fi
	if [ -z "${JARMIN_HOME}" ]; then echo "Error: JARMIN_HOME not set!"; exit -1; fi
	if [ -z "${JAVA_HOME_FOR_QUARKUS}" ]; then echo "Error: JAVA_HOME_FOR_QUARKUS not set!"; exit -1; fi
}

function setJVMLogs() {
	if [ -z "${RESULTS_DIR}" ]; then RESULTS_DIR="results"; fi
	if [ -z "${JIT_SETTINGS}" ]; then JIT_SETTINGS=""; fi

	SCC_DIR="${currentDir}/.classCache"
	JAVACORE="${RESULTS_DIR}/javacore.txt"
	# clean up any existing cache
	rm -fr ${SCC_DIR}

	echo "Settings for JVM:"
	echo "TR_IProfileMore: ${TR_IProfileMore}"
	echo "SCC_DIR: ${SCC_DIR}"
	echo "JIT_LOG: ${JIT_LOG}"
	echo "JAVACORE: ${JAVACORE}"
	echo "JIT_SETTINGS: ${JIT_SETTINGS}"
}

currentDir="${PWD}"
if [ $# -gt "0" ];
then
	RESULTS_DIR=$1
fi

if [ -z "${RESULTS_DIR}" ]; then RESULTS_DIR="results"; fi
mkdir -p ${RESULTS_DIR} &> /dev/null

JMETER_OUTPUT="${RESULTS_DIR}/jmeter.out"
TOP_OUTPUT_PHASE1="${RESULTS_DIR}/top_phase1.out"
TOP_OUTPUT_PHASE2="${RESULTS_DIR}/top_phase2.out"
TOP_OUTPUT_PHASE3="${RESULTS_DIR}/top_phase3.out"
MEM_OUTPUT_PHASE1="${RESULTS_DIR}/memory_phase1.out"
MEM_OUTPUT_PHASE2="${RESULTS_DIR}/memory_phase2.out"
MEM_OUTPUT_PHASE3="${RESULTS_DIR}/memory_phase3.out"
PMAP_PHASE1="${RESULTS_DIR}/pmap_phase1.out"
PMAP_PHASE2="${RESULTS_DIR}/pmap_phase2.out"
PMAP_PHASE3="${RESULTS_DIR}/pmap_phase3.out"
CPU_OUTPUT="${RESULTS_DIR}/cpu.out"
STATS_FILE="${RESULTS_DIR}/stats"

setDefaultConfig
checkConfig
setJVMLogs

app_pid=`ps -ef | grep rest-http-crud-quarkus | grep -v grep | awk '{ print $2 }'`

if [ ! -z "${app_pid}" ];
then
	echo "Quarkus app (pid: ${app_pid}) is already running. Stop it first."
	echo "Exiting"
	exit 1
fi

if [ "${DO_PERF_PROFILING}" -eq "1" ];
then
	taskset -c 2,3 stdbuf -oL ${JAVA_HOME_FOR_QUARKUS}/bin/java -agentpath:/home/asmehra/data/IBM/linux/tools/perf/libperf-jvmti.so -Xdump:none -Xdump:java:events=user,file=${JAVACORE} -Xnoaot "${JIT_SETTINGS}" "-Xshareclasses:name=quarkus,cacheDir=${SCC_DIR}" -Xscmx80m -Xms128m -Xmx128m -jar target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner.jar &> ${RESULTS_DIR}/quarkus.log &
else
	if [ "${NATIVE_IMAGE}" -eq "1" ]; then
		taskset -c 2,3 stdbuf -oL ./target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner -Xmx128m -Xmn110m -Xms100m -Dhttp.host=0.0.0.0 &> ${RESULTS_DIR}/quarkus.log &
	else
		taskset -c 2,3 stdbuf -oL ${JAVA_HOME_FOR_QUARKUS}/bin/java -Xdump:none -Xdump:java:events=user,file=${JAVACORE} -Xnoaot "${JIT_SETTINGS}" "-Xshareclasses:name=quarkus,cacheDir=${SCC_DIR}" -Xscmx80m -Xms28m -Xmx28m -jar target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner.jar &> ${RESULTS_DIR}/quarkus.log &
	fi
fi

if [ $? -ne "0" ];
then
	echo "Error in starting the app...check the logs"
	exit 1;
fi

sleep 5s

counter=0
max_iterations=300
while [ "${counter}" -lt "${max_iterations}" ];
do
	grep "rest-http-crud-quarkus.*started in" ${RESULTS_DIR}/quarkus.log &> /dev/null
	if [ $? -eq "0" ];
	then
		break;
	fi
	sleep 1s
	counter=$(( $counter+1 ))
done

grep "rest-http-crud-quarkus.*started in" ${RESULTS_DIR}/quarkus.log &> /dev/null
if [ $? -ne "0" ];
then
	echo "Application is taking too long to startup...Exiting"
	exit 1
fi

app_pid=`ps -ef | grep rest-http-crud-quarkus | grep -v "perf record" | grep -v grep | awk '{ print $2 }'`
echo "app pid: ${app_pid}"

top -b -n 1 -p "${app_pid}" &> ${TOP_OUTPUT_PHASE1}

if [ "${NATIVE_IMAGE}" -eq "0" ]; then
	grep "${app_pid}" ${TOP_OUTPUT_PHASE1} | grep "java" | awk '{ print $6 }' &> ${MEM_OUTPUT_PHASE1}
else
	grep "${app_pid}" ${TOP_OUTPUT_PHASE1} | grep "rest-http" | awk '{ print $6 }' &> ${MEM_OUTPUT_PHASE1}
fi
mem_phase1=`cat ${MEM_OUTPUT_PHASE1}`

pmap -X ${app_pid} &> ${PMAP_PHASE1}

if [ "${NATIVE_IMAGE}" -eq "0" ]; then

	# Phase 1

	kill -3 ${app_pid}
	sleep 5s
	mv ${RESULTS_DIR}/javacore.txt ${RESULTS_DIR}/javacore.phase1
	cp ${JIT_LOG} ${RESULTS_DIR}/jit.log.phase1
	echo "Phase 1 done"
	phase1LineCount=`wc -l ${JIT_LOG} | awk '{print $1}'`
	phase1LineCount=$(( $phase1LineCount + 1 ))

	if [ ! -z "${TR_RegisterForSigUsr}" ] && [ "${JARMIN_PHASE}" = "phase1" ];
	then
		echo "Starting Jarmin in phase 1"
		kill -10 ${app_pid}
		counter=0
		max_iterations=120
		while [ "${counter}" -lt "${max_iterations}" ];
		do
			grep "Compilation Done" ${RESULTS_DIR}/quarkus.log &> /dev/null
			if [ $? -eq "0" ];
			then
				break;
			fi
			sleep 5s
			counter=$(( $counter+1 ))
		done
		grep "Compilation Done" ${RESULTS_DIR}/quarkus.log &> /dev/null
		if [ $? -ne "0" ];
		then
			echo "JVM is taking too long to compile methods...Exiting"
			break;
		fi
		cp ${JIT_LOG} ${RESULTS_DIR}/jit.log.afterjarmincomp
	fi
fi

# Phase 2

# numactl --physcpubind="0-3" --membind="0" /home/asmehra/data/apache-jmeter-5.2.1/bin/jmeter -JDURATION=1 -n -t jmeter_restcrud.quarkus.jmx


<< 'COMMENT'
i=0
while [ "$i" -lt "10000" ];
do
	if [ "$i" -lt "100" ];
	then
		rem=$(( $i % 5 ))
	elif [ "$i" -lt "1000" ];
	then
		rem=$(( $i % 50 ))
	else
		rem=$(( $i % 100 ))
	fi
	if [ "$rem" -eq "0" ]; then
		memory=`pmap -x ${app_pid} | grep total | awk '{ print $4 }'`
		echo "$i,$memory" >> ${RESULTS_DIR}/memory_usage
	fi
	curl -s localhost:8080/fruits &> /dev/null
	if [ $? -ne "0" ];
	then
		echo "Request failed, exit code: $?"
		exit
	fi
	i=$(( $i + 1 ))
	rem=$(( $i % 100 ))
	if [ "$rem" -eq "0" ]; then
		echo "Completed $i requests"
	fi
done

COMMENT

echo "Using ${NUM_REQUESTS} requests in phase 2"

for i in `seq 1 ${NUM_REQUESTS}`; do
	response=`curl -s localhost:8080/fruits`
	if [ $? -ne "0" ];
	then
		echo "First request failed, exit code: $?"
		echo "Exiting"
		exit
	fi
	echo "Response for request: ${response}"
	echo ${response} | grep "Apple" &> /dev/null
	if [ $? -ne "0" ];
	then
		echo "Did not get expected response. Exiting."
		exit
	fi
done

top -b -n 1 -p "${app_pid}" &> ${TOP_OUTPUT_PHASE2}

if [ "${NATIVE_IMAGE}" -eq "0" ]; then
	grep "${app_pid}" ${TOP_OUTPUT_PHASE2} | grep "java" | awk '{ print $6 }' &> ${MEM_OUTPUT_PHASE2}
else
	grep "${app_pid}" ${TOP_OUTPUT_PHASE2} | grep "rest-http" | awk '{ print $6 }' &> ${MEM_OUTPUT_PHASE2}
fi
mem_phase2=`cat ${MEM_OUTPUT_PHASE2}`

pmap -X ${app_pid} &> ${PMAP_PHASE2}

if [ "${NATIVE_IMAGE}" -eq "0" ]; then
	kill -3 ${app_pid}
	sleep 5s
	mv ${RESULTS_DIR}/javacore.txt ${RESULTS_DIR}/javacore.phase2
	cp ${JIT_LOG} ${RESULTS_DIR}/jit.log.phase2.tmp
	phase2Start=$(( $phase1LineCount + 1 ))
	tail -n +${phase2Start} ${RESULTS_DIR}/jit.log.phase2.tmp > ${RESULTS_DIR}/jit.log.phase2
	rm -f ${RESULTS_DIR}/jit.log.phase2.tmp

	phase2LineCount=`wc -l ${JIT_LOG} | awk '{print $1}'`
	phase2LineCount=$(( $phase2LineCount + 1 ))

	if [ ! -z "${TR_RegisterForSigUsr}" ] && [ "${JARMIN_PHASE}" = "phase2" ];
	then
		if [ -z "${TR_DoNotRunJarmin}" ];
		then
			echo "Starting Jarmin in phase 2"
			kill -10 ${app_pid}
			while true;
			do
				grep "Compilation Done" ${RESULTS_DIR}/quarkus.log &> /dev/null
				if [ $? -eq "0" ];
				then
					break;
				fi
				sleep 5s
			done
			kill -3 ${app_pid}
			sleep 5s
			mv ${RESULTS_DIR}/javacore.txt ${RESULTS_DIR}/javacore.afterjarmincomp
			cp ${JIT_LOG} ${RESULTS_DIR}/jit.log.afterjarmincomp.tmp
			phase2Start=$(( $phase2LineCount + 1 ))
			tail -n +${phase2Start} ${RESULTS_DIR}/jit.log.afterjarmincomp.tmp > ${RESULTS_DIR}/jit.log.afterjarmincomp
			rm -f ${RESULTS_DIR}/jit.log.afterjarmincomp.tmp

			phase2LineCount=`wc -l ${JIT_LOG} | awk '{print $1}'`
			phase2LineCount=$(( $phase2LineCount + 1 ))
		fi
	fi

	echo "Phase 2 done"

fi

# Phase 3

taskset -c 1 ./run_top.sh "${app_pid}" &> ${TOP_OUTPUT_PHASE3} &
sleep 1s
top_pid=`ps -ef | grep "top -b" | grep -v grep | awk '{ print $2 }'`
echo "top_pid: ${top_pid}"

# << 'COMMENT'
if [ "${DO_PERF_PROFILING}" -eq "1" ];
then
	#numactl --physcpubind="0-3" --membind="0" /root/ashu/linux/tools/perf/perf record -o ${RESULTS_DIR}/perf.data -k 1 -i -p ${app_pid} -e cycles &
	taskset -c 0,1,2,3 /home/asmehra/data/IBM/linux/tools/perf/perf record -o ${RESULTS_DIR}/perf.data -k 1 -i -p ${app_pid} -e cycles &
	#tid_hex=`grep -A 3 "executor-thread-1" ${RESULTS_DIR}/javacore.phase2 | grep "native thread ID" | cut -d ':' -f 2 | cut -d ',' -f 1 | cut -d 'x' -f 2`
	#tid=`echo "obase=10; ibase=16; ${tid_hex}" | bc`
	#echo "Profiling thread ${tid}"
	#numactl --physcpubind="0-3" --membind="0" /root/ashu/linux/tools/perf/perf record --tid=${tid} -o ${RESULTS_DIR}/perf.data -k 1 -i -p ${app_pid} -e cycles &
	sleep 1s
	perf_pid=`ps -ef | grep "perf record" | grep -v grep | awk '{ print $2 }'`
	echo "perf pid: ${perf_pid}"
fi
# COMMENT

taskset -c 0,1,4,5 /home/asmehra/data/apache-jmeter-5.2.1/bin/jmeter -JDURATION=300 -JTHREADS=${JMETER_THREADS} -Dsummariser.interval=6 -n -t jmeter_restcrud.quarkus.jmx | tee ${JMETER_OUTPUT}

if [ ! -z "${TR_RegisterForSigUsr}" ] && [ -z "${TR_DoNotRunJarmin}" ];
then
	mv /tmp/rootmethods.log ${RESULTS_DIR}
	mv /tmp/jarmin_methods.log ${RESULTS_DIR}
	mv /tmp/javamethods.log ${RESULTS_DIR}
	mv /tmp/classesNotFound.log ${RESULTS_DIR}
fi

if [ "${NATIVE_IMAGE}" -eq "0" ]; then
	kill -3 ${app_pid}
	sleep 5s
	mv ${RESULTS_DIR}/javacore.txt ${RESULTS_DIR}/javacore.phase3
	cp ${JIT_LOG} ${RESULTS_DIR}/jit.log.phase3.tmp
	phase3Start=$(( $phase2LineCount + 1 ))
	tail -n +${phase3Start} ${RESULTS_DIR}/jit.log.phase3.tmp > ${RESULTS_DIR}/jit.log.phase3
	rm -f ${RESULTS_DIR}/jit.log.phase3.tmp

	echo "Phase 3 done"
fi

kill -9 ${top_pid}
if [ "${NATIVE_IMAGE}" -eq "0" ]; then
	grep "${app_pid}" ${TOP_OUTPUT_PHASE3} | grep "java" | awk '{ print $6 }' &> ${MEM_OUTPUT_PHASE3}
	grep "${app_pid}" ${TOP_OUTPUT_PHASE3} | grep "java" | awk '{ print $9 }' &> ${CPU_OUTPUT}
else
	grep "${app_pid}" ${TOP_OUTPUT_PHASE3} | grep "rest-http" | awk '{ print $6 }' &> ${MEM_OUTPUT_PHASE3}
	grep "${app_pid}" ${TOP_OUTPUT_PHASE3} | grep "rest-http" | awk '{ print $9 }' &> ${CPU_OUTPUT}
fi
max_mem=`cat ${MEM_OUTPUT_PHASE3} | sort -n | tail -n 1`
avg_cpu=`awk 'BEGIN{sum=0}{sum += $1}END{print sum/NR}' ${CPU_OUTPUT}`
pmap -X ${app_pid} &> ${PMAP_PHASE3}

# Get all the stats

grep "summary +" ${JMETER_OUTPUT} | grep "00:00:06" | awk '{ print $7 }' | cut -d '/' -f 1 > ${RESULTS_DIR}/rampup
tail -n 20 ${RESULTS_DIR}/rampup > ${RESULTS_DIR}/rampup.last2mins
avg_tput=`grep "summary =" ${JMETER_OUTPUT} | tail -n 1 | awk '{ print $7 }' | cut -d '/' -f 1`
avg_tput_last2min=`cat ${RESULTS_DIR}/rampup.last2mins | awk 'BEGIN{sum=0}{sum += $1}END{print sum/NR}'`
peak_tput=`cat ${RESULTS_DIR}/rampup | sort -n | tail -n 1`
peak_tput_last2min=`cat ${RESULTS_DIR}/rampup.last2mins | sort -n | tail -n 1`

echo "Overall Avg tput: ${avg_tput}" | tee -a ${STATS_FILE}
echo "Overall Peak tput: ${peak_tput}" | tee -a ${STATS_FILE}
echo "Avg tput (last 2 mins): ${avg_tput_last2min}" | tee  -a ${STATS_FILE}
echo "Peak tput (last 2 mins): ${peak_tput_last2min}" | tee  -a ${STATS_FILE}

echo "Memory after phase1: ${mem_phase1}" | tee -a ${STATS_FILE}
echo "Memory after phase2: ${mem_phase2}" | tee -a ${STATS_FILE}
echo "Peak memory: ${max_mem} KB" | tee -a ${STATS_FILE}
echo "Avg cpu: ${avg_cpu}" | tee -a ${STATS_FILE}

trap "kill ${perf_pid} ${app_pid}" INT
#trap "kill ${app_pid}" INT

kill -2 $$ # sending SIGINT to itself so that it can trap and send it to its child
wait
sleep 1s

if [ "${DO_PERF_PROFILING}" -eq "1" ];
then
	/home/asmehra/data/IBM/linux/tools/perf/perf inject -i ${RESULTS_DIR}/perf.data --jit -o ${RESULTS_DIR}/perf.data.jitted
	/home/asmehra/data/IBM/linux/tools/perf/perf report -i ${RESULTS_DIR}/perf.data.jitted > ${RESULTS_DIR}/perf.jitted.report
	#mv perf.data ${RESULTS_DIR}
	#mv perf.data.jitted ${RESULTS_DIR}
fi
