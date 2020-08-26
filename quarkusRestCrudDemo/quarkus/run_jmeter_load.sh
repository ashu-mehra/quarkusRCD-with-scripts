#!/bin/bash

ulimit -c unlimited

export QUARKUS_REST_CRUD_APP="/home/ashu/quarkusRestCrudDemo"
export JARMIN_HOME="/home/ashu/jarmin/"

if [ -z "${JAVA_HOME}" ];
then
	export JAVA_HOME="/root/ashu/builds/openj9/jdk8u252-b09"
fi

if [ $# -gt "0" ];
then
	RESULTS_DIR=$1
fi

if [ -z "${RESULTS_DIR}" ];
then
	RESULTS_DIR="results"
fi

# env var to control jarmin execution from the JVM 
#export TR_IProfileMore=1
#export TR_FlushProfilingBuffers=1
export TR_JarminReductionMode="class"
export TR_RegisterForSignalToInvokeJarmin=1
#export TR_DoNotRunJarmin=1
#export TR_AllowCompileAfterJarmin=1

JARMIN_PHASE="phase2" # valid values: phase1 or phase2

SCC_DIR="/home/ashu/quarkusRestCrudDemo/quarkus/.classCache"
DO_PERF_PROFILING=0
#NUM_REQUESTS=1

echo "JAVA_HOME: ${JAVA_HOME}"
echo "RESULTS_DIR: ${RESULTS_DIR}"

echo "SCC_DIR: ${SCC_DIR}"
rm -fr ${SCC_DIR}

mkdir -p ${RESULTS_DIR} &> /dev/null

JIT_LOG="${RESULTS_DIR}/jit.log"
JAVACORE="${RESULTS_DIR}/javacore.txt"

java_pid=`ps -ef | grep rest-http-crud-quarkus | grep -v grep | awk '{ print $2 }'`

if [ ! -z "${java_pid}" ];
then
	echo "Java process (pid: ${java_pid}) is already running. Stop it first."
	echo "Exiting"
	exit 1
fi

#JIT_OPTION="-Xjit:traceRelocatableDataDetailsRT,traceRelocatableDataRT,log=log,aotrtDebugLevel=30,rtLog=rtLog -Xaot:traceRelocatableDataDetailsRT,traceRelocatableDataRT,aotrtDebugLevel=30"

#JIT_COUNT_SETTINGS=",count=0,bcount=0,disableAsyncCompilation,disableInlining"
#JIT_COUNT_SETTINGS=",disableAsyncCompilation,{java/util/ArrayList.add(Ljava/lang/Object;)Z}(log=aladd.log,traceInlining,traceBlockFrequencyGeneration,optDetails),{java/util/ArrayList.ensureExplicitCapacity*}(log=alensure.log,traceBlockFrequencyGeneration,optDetails),inlinerVeryColdBorderFrequency=1000"
#JIT_COUNT_SETTINGS=",disableAsyncCompilation,disableConservativeColdInlining,disableConservativeInlining,bigCalleeThreshold=600,bigCalleeHotOptThreshold=600,bigCalleeScorchingOptThreshold=600,inlineVeryLargeCompiledMethods"
#JIT_COUNT_SETTINGS=",disableAsyncCompilation,disableInlining"
#JIT_COUNT_SETTINGS=",disableAsyncCompilation,disableProfiledInlining"
#JIT_COUNT_SETTINGS=",count=0,bcount=0,disableAsyncCompilation"
#JIT_COUNT_SETTINGS=",disableAsyncCompilation,disableGuardedCountingRecompilation"
JIT_COUNT_SETTINGS=",disableAsyncCompilation,disableGuardedCountingRecompilation"
#JIT_COUNT_SETTINGS=",count=1,bcount=1,disableAsyncCompilation"
#JIT_COUNT_SETTINGS=",count=0,bcount=0,disableAsyncCompilation"
#JIT_COUNT_SETTINGS=",count=0,bcount=0,disableAsyncCompilation,initialOptLevel=hot,dontDowngradeToCold"

#numactl --physcpubind="28-31" --membind="1" ${JAVA_HOME}/bin/java -Xdump:none -Xdump:java:events=user,file=${JAVACORE} -Xnoaot "-Xjit:verbose={compilePerformance,compileExclude,counts,inlining},vlog=${JIT_LOG},disableSuffixLogs${JIT_COUNT_SETTINGS}" "-Xshareclasses:name=quarkus,cacheDir=${SCC_DIR}" -Xscmx80m -Xms128m -Xmx128m -jar target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner.jar &> ${RESULTS_DIR}/quarkus.log &

#numactl --physcpubind="28-31" --membind="1" ${JAVA_HOME}/bin/java ${JIT_OPTION} "-Xshareclasses:name=quarkus,cacheDir=${SCC_DIR}" -Xscmx80m -Xms128m -Xmx128m -jar target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner.jar &> ${RESULTS_DIR}/quarkus.log &

if [ ! -z "${DO_PERF_PROFILING}" ] && [ "${DO_PERF_PROFILING}" -eq "1" ];
then
	numactl --physcpubind="28-31" --membind="1" stdbuf -oL /root/ashu/builds/openj9/jarmin_builds/j2sdk-image/bin/java -Dquarkus.thread-pool.max-threads=1 -agentpath:/root/ashu/linux/tools/perf/libperf-jvmti.so -Xdump:none -Xdump:java:events=user,file=${JAVACORE} -Xnoaot "-Xjit:verbose={compilePerformance,compileExclude,counts,inlining},vlog=${JIT_LOG},iprofilerVerbose,disableSuffixLogs${JIT_COUNT_SETTINGS}" "-Xshareclasses:name=quarkus,cacheDir=${SCC_DIR}" -Xscmx80m -Xms128m -Xmx128m -jar target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner.jar &> ${RESULTS_DIR}/quarkus.log &
else
	#numactl --physcpubind="28-31" --membind="1" stdbuf -oL /root/ashu/builds/openj9/jarmin_builds/j2sdk-image/bin/java -Dquarkus.thread-pool.max-threads=1 -Xdump:none -Xdump:java:events=user,file=${JAVACORE} -Xnoaot "-Xjit:verbose={compilePerformance,compileExclude,counts,inlining},vlog=${JIT_LOG},iprofilerVerbose,disableSuffixLogs${JIT_COUNT_SETTINGS}" "-Xshareclasses:name=quarkus,cacheDir=${SCC_DIR}" -Xscmx80m -Xms128m -Xmx128m -jar target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner.jar &> ${RESULTS_DIR}/quarkus.log &
	numactl --physcpubind="28-31" --membind="1" stdbuf -oL /root/ashu/builds/openj9/jarmin_builds/j2sdk-image/bin/java -Xdump:none -Xdump:java:events=user,file=${JAVACORE} -Xnoaot "-Xjit:verbose={compilePerformance,compileExclude,counts,inlining},vlog=${JIT_LOG},iprofilerVerbose,disableSuffixLogs${JIT_COUNT_SETTINGS}" "-Xshareclasses:name=quarkus,cacheDir=${SCC_DIR}" -Xscmx80m -Xms128m -Xmx128m -jar target/rest-http-crud-quarkus-1.0.0.Alpha1-SNAPSHOT-runner.jar &> ${RESULTS_DIR}/quarkus.log &
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
	echo "JVM is taking too long to startup...Exiting"
	exit 1
fi

java_pid=`ps -ef | grep rest-http-crud-quarkus | grep -v "perf record" | grep -v grep | awk '{ print $2 }'`
echo "java pid: ${java_pid}"

# Phase 1

kill -3 ${java_pid}
sleep 5s
mv ${RESULTS_DIR}/javacore.txt ${RESULTS_DIR}/javacore.phase1
cp ${JIT_LOG} ${RESULTS_DIR}/jit.log.phase1
echo "Phase 1 done"
phase1LineCount=`wc -l ${RESULTS_DIR}/jit.log.phase1 | awk '{print $1}'`
phase1LineCount=$(( $phase1LineCount + 1 ))

if [ ! -z "${TR_RegisterForSignalToInvokeJarmin}" ] && [ "${TR_RegisterForSignalToInvokeJarmin}" -eq "1" ] && [ "${JARMIN_PHASE}" = "phase1" ];
then
	echo "Starting Jarmin in phase 1"
	kill -10 ${java_pid}
	while true;
	do
		grep "Compilation Done" ${RESULTS_DIR}/quarkus.log &> /dev/null
		if [ $? -eq "0" ];
		then
			break;
		fi
		sleep 5s
	done
	cp ${JIT_LOG} ${RESULTS_DIR}/jit.log.afterjarmincomp
fi

# Phase 2

# numactl --physcpubind="84-111" --membind="1" /root/ashu/apache-jmeter-5.2.1/bin/jmeter -JDURATION=1 -n -t jmeter_restcrud.quarkus.jmx

if [ -z "${NUM_REQUESTS}" ];
then
	NUM_REQUESTS=1
fi

if [ -z "${NUM_URLS}" ];
then
	NUM_URLS=1
fi

<< 'COMMENT'
if [ "${NUM_REQUESTS}" -eq "10" ];
then
	for char in {a..j};
	do
		response=`curl -s localhost:8080/frui${char}s`
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
fi
COMMENT

#<< 'COMMENT'
echo "Using ${NUM_REQUESTS} requests in phase 2"

if [ "${NUM_URLS}" -eq "2" ]; then
	count=0
	while [ ${count} -lt ${NUM_REQUESTS} ];
	do
		echo "Request using first url"
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
		count=$(( $count + 1 ))
		if [ ${count} -eq ${NUM_REQUESTS} ];
		then
			break
		fi

		echo "Request using second url"
		response=`curl -s localhost:8080/fruiss`
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
		count=$(( $count + 1 ))
		if [ ${count} -eq ${NUM_REQUESTS} ];
		then
			break
		fi
	done
elif [ "${NUM_URLS}" -eq "1" ]; then
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
fi
#COMMENT

kill -3 ${java_pid}
sleep 5s
mv ${RESULTS_DIR}/javacore.txt ${RESULTS_DIR}/javacore.phase2
cp ${JIT_LOG} ${RESULTS_DIR}/jit.log.phase2.tmp
phase2Start=$(( $phase1LineCount + 1 ))
tail -n +${phase2Start} ${RESULTS_DIR}/jit.log.phase2.tmp > ${RESULTS_DIR}/jit.log.phase2
rm -f ${RESULTS_DIR}/jit.log.phase2.tmp

phase2LineCount=`wc -l ${RESULTS_DIR}/jit.log.phase2 | awk '{print $1}'`
phase2LineCount=$(( $phase2LineCount + 1 ))

if [ ! -z "${TR_RegisterForSignalToInvokeJarmin}" ] && [ "${TR_RegisterForSignalToInvokeJarmin}" -eq "1" ] && [ "${JARMIN_PHASE}" = "phase2" ];
then
	if [ -z "${TR_DoNotRunJarmin}" ];
	then
		echo "Starting Jarmin in phase 2"
		kill -10 ${java_pid}
		while true;
		do
			grep "Compilation Done" ${RESULTS_DIR}/quarkus.log &> /dev/null
			if [ $? -eq "0" ];
			then
				break;
			fi
			sleep 5s
		done
		cp ${JIT_LOG} ${RESULTS_DIR}/jit.log.afterjarmincomp.tmp
		phase2Start=$(( $phase1LineCount + 1 ))
		tail -n +${phase2Start} ${RESULTS_DIR}/jit.log.afterjarmincomp.tmp > ${RESULTS_DIR}/jit.log.afterjarmincomp
		rm -f ${RESULTS_DIR}/jit.log.afterjarmincomp.tmp

		phase2LineCount=`wc -l ${RESULTS_DIR}/jit.log.afterjarmincomp | awk '{print $1}'`
		phase2LineCount=$(( $phase2LineCount + 1 ))
	fi
fi

echo "Phase 2 done"


# Phase 3

JMETER_OUTPUT="${RESULTS_DIR}/jmeter.out"
TOP_OUTPUT="${RESULTS_DIR}/top.out"
MEM_OUTPUT="${RESULTS_DIR}/memory.out"
CPU_OUTPUT="${RESULTS_DIR}/cpu.out"

./run_top.sh "${java_pid}" &> ${TOP_OUTPUT} &
sleep 1s
top_pid=`ps -ef | grep "top -b" | grep -v grep | awk '{ print $2 }'`
echo "top_pid: ${top_pid}"

# << 'COMMENT'
if [ ! -z "${DO_PERF_PROFILING}" ] && [ "${DO_PERF_PROFILING}" -eq "1" ];
then
	#numactl --physcpubind="36-39" --membind="1" /root/ashu/linux/tools/perf/perf record -o ${RESULTS_DIR}/perf.data --call-graph dwarf -k 1 -i -p ${java_pid} -e cycles &
	tid_hex=`grep -A 3 "executor-thread-1" ${RESULTS_DIR}/javacore.phase2 | grep "native thread ID" | cut -d ':' -f 2 | cut -d ',' -f 1 | cut -d 'x' -f 2`
	tid=`echo "obase=10; ibase=16; ${tid_hex}" | bc`
	echo "Profiling thread ${tid}"
	numactl --physcpubind="36-39" --membind="1" /root/ashu/linux/tools/perf/perf record --tid=${tid} -o ${RESULTS_DIR}/perf.data -k 1 -i -p ${java_pid} -e cycles &
	sleep 1s
	perf_pid=`ps -ef | grep "perf record" | grep -v grep | awk '{ print $2 }'`
	echo "perf pid: ${perf_pid}"
fi
# COMMENT

#numactl --physcpubind="84-111" --membind="1" /root/ashu/apache-jmeter-5.2.1/bin/jmeter -JTHREADS=1 -JDURATION=300 -Dsummariser.interval=6 -n -t jmeter_restcrud.quarkus.jmx | tee ${JMETER_OUTPUT}
numactl --physcpubind="84-111" --membind="1" /root/ashu/apache-jmeter-5.2.1/bin/jmeter -JDURATION=300 -Dsummariser.interval=6 -n -t jmeter_restcrud.quarkus.jmx | tee ${JMETER_OUTPUT}

echo "Phase 3 done"

if [ ! -z "${TR_RegisterForSignalToInvokeJarmin}" ] && [ "${TR_RegisterForSignalToInvokeJarmin}" -eq "1" ] && [ -z "${TR_DoNotRunJarmin}" ];
then
	mv /tmp/rootmethods.log ${RESULTS_DIR}
	mv /tmp/jarmin_methods.log ${RESULTS_DIR}
	mv /tmp/javamethods.log ${RESULTS_DIR}
fi


kill -3 ${java_pid}
sleep 5s
mv ${RESULTS_DIR}/javacore.txt ${RESULTS_DIR}/javacore.phase3

kill -9 ${top_pid}
grep "${java_pid}" ${TOP_OUTPUT} | grep "java" | awk '{ print $6 }' &> ${MEM_OUTPUT}
max_mem=`cat ${MEM_OUTPUT} | sort -n | tail -n 1`
grep "${java_pid}" ${TOP_OUTPUT} | grep "java" | awk '{ print $9 }' &> ${CPU_OUTPUT}
avg_cpu=`awk 'BEGIN{sum=0}{sum += $1}END{print sum/NR}' ${CPU_OUTPUT}`

cp ${JIT_LOG} ${RESULTS_DIR}/jit.log.phase3.tmp
phase3Start=$(( $phase1LineCount + $phase2LineCount + 1 ))
tail -n +${phase3Start} ${RESULTS_DIR}/jit.log.phase3.tmp > ${RESULTS_DIR}/jit.log.phase3
rm -f ${RESULTS_DIR}/jit.log.phase3.tmp

# Get all the stats

OUTPUT_FILE="${RESULTS_DIR}/stats"

grep "summary +" ${JMETER_OUTPUT} | grep "00:00:06" | awk '{ print $7 }' | cut -d '/' -f 1 > ${RESULTS_DIR}/rampup
tail -n 20 ${RESULTS_DIR}/rampup > ${RESULTS_DIR}/rampup.last2mins
avg_tput=`grep "summary =" ${JMETER_OUTPUT} | tail -n 1 | awk '{ print $7 }' | cut -d '/' -f 1`
avg_tput_last2min=`cat ${RESULTS_DIR}/rampup.last2mins | awk 'BEGIN{sum=0}{sum += $1}END{print sum/NR}'`
peak_tput=`cat ${RESULTS_DIR}/rampup | sort -n | tail -n 1`
peak_tput_last2min=`cat ${RESULTS_DIR}/rampup.last2mins | sort -n | tail -n 1`

if [ ! -z "${TR_RegisterForSignalToInvokeJarmin}" ] && [ "${TR_RegisterForSignalToInvokeJarmin}" -eq "1" ];
then
	python uniquejitcompilations.py ${RESULTS_DIR}/jit.log.phase1 > ${RESULTS_DIR}/jit.log.phase1.analysis
	python uniquejitcompilations.py ${RESULTS_DIR}/jit.log.phase2 > ${RESULTS_DIR}/jit.log.phase2.analysis
	python uniquejitcompilations.py ${RESULTS_DIR}/jit.log.phase3 > ${RESULTS_DIR}/jit.log.phase3.analysis
	if [ -z "${TR_DoNotRunJarmin}" ];
	then
		python uniquejitcompilations.py ${RESULTS_DIR}/jit.log.afterjarmincomp > ${RESULTS_DIR}/jit.log.afterjarmincomp.analysis
	fi
fi

#total_unique_phase1=`grep "unique compilations" ${RESULTS_DIR}/jit.unique.phase1 | awk '{ print $3 }'`
#echo "total_unique_phase1=${total_unique_phase1}" | tee -a ${OUTPUT_FILE}

#total_unique_phase2=`grep "unique compilations" ${RESULTS_DIR}/jit.unique.phase2 | awk '{ print $3 }'`
#echo "total_unique_phase2=${total_unique_phase2}" | tee -a ${OUTPUT_FILE}

#total_unique_phase3=`grep "unique compilations" ${RESULTS_DIR}/jit.unique.phase3 | awk '{ print $3 }'`
#echo "total_unique_phase3=${total_unique_phase3}" | tee -a ${OUTPUT_FILE}

#phase1=${total_unique_phase1}
#phase2=$(( $total_unique_phase2-$total_unique_phase1 ))
#phase3=$(( $total_unique_phase3-$total_unique_phase2 ))

#echo "Phase 1 compilations: ${phase1}" | tee -a ${OUTPUT_FILE}
#echo "Phase 2 compilations: ${phase2}" | tee -a ${OUTPUT_FILE}
#echo "Phase 3 compilations: ${phase3}" | tee -a ${OUTPUT_FILE}

#python jitcompiles_phase_analysis.py ${RESULTS_DIR}/jit.log.phase1 ${RESULTS_DIR}/jit.log.phase2 ${RESULTS_DIR}/jit.log.phase3 | tee -a ${OUTPUT_FILE}

echo "Overall Avg tput: ${avg_tput}" | tee -a ${OUTPUT_FILE}
echo "Overall Peak tput: ${peak_tput}" | tee -a ${OUTPUT_FILE}
echo "Avg tput (last 2 mins): ${avg_tput_last2min}" | tee  -a ${OUTPUT_FILE}
echo "Peak tput (last 2 mins): ${peak_tput_last2min}" | tee  -a ${OUTPUT_FILE}

echo "Peak memory: ${max_mem} KB" | tee -a ${OUTPUT_FILE}
echo "Avg cpu: ${avg_cpu}" | tee -a ${OUTPUT_FILE}

trap "kill ${perf_pid} ${java_pid}" INT
#trap "kill ${java_pid}" INT

kill -2 $$ # sending SIGINT to itself so that it can trap and send it to its child
wait
sleep 1s

if [ ! -z "${DO_PERF_PROFILING}" ] && [ "${DO_PERF_PROFILING}" -eq "1" ];
then
	/root/ashu/linux/tools/perf/perf inject -i ${RESULTS_DIR}/perf.data --jit -o ${RESULTS_DIR}/perf.data.jitted
	#mv perf.data ${RESULTS_DIR}
	#mv perf.data.jitted ${RESULTS_DIR}
fi
