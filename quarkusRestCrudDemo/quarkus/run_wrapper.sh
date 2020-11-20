#!/bin/bash

checkJre() {
	if [ ! -d "${PWD}/jre" ]; then
		echo "JRE not found. Downloading it"
		wget --progress=dot:mega -O jre.tar.gz "https://api.adoptopenjdk.net/v3/binary/latest/8/ga/linux/x64/jre/openj9/normal/adoptopenjdk"
		mkdir -p jre
		tar -xzf jre.tar.gz --directory=jre/ --strip=1
		rm -f jre.tar.gz
	fi
	echo "JRE version:"
	./jre/bin/java -version
	echo
}

checkJreWithJarmin() {
	if [ ! -d "${PWD}/jdk-with-jarmin" ]; then
		echo "JRE with jarmin not found. Downloading it"
		git clone --depth=1 https://github.com/ashu-mehra/jdk-with-jarmin.git
	fi
	echo "JRE with Jarmin version:"
	./jdk-with-jarmin/j2re-image/bin/java -version
	echo
}

checkJmeter() {
	if [ ! -d jmeter ]; then
		if [ ! -f apache-jmeter-5.2.1.zip ]; then
			wget --progress=dot:mega https://httpd-mirror.sergal.org/apache//jmeter/binaries/apache-jmeter-5.2.1.zip
		fi
		unzip -q apache-jmeter-5.2.1.zip
		mv apache-jmeter-5.2.1 jmeter
	fi
}

start_db() {
	DB_CONTAINER_NAME="postgres-quarkus-rest-http-crud"

	docker run --network=host -d --cpuset-cpus=4-7 --cpuset-mems=0 --ulimit memlock=-1:-1 -it --memory-swappiness=0 --name ${DB_CONTAINER_NAME} -e POSTGRES_USER=restcrud -e POSTGRES_PASSWORD=restcrud -e POSTGRES_DB=rest-crud -p 5432:5432 postgres:10.5
	if [ $? -ne "0" ]; then
		echo "Failed to start docker container for postgres db...Exiting"
		exit -1
	fi
	sleep 10s
	echo "Docker containers:"
	docker ps -a
	echo "DB logs:"
	docker logs ${DB_CONTAINER_NAME}
}

stop_db() {
	DB_CONTAINER_NAME="postgres-quarkus-rest-http-crud"

	docker stop ${DB_CONTAINER_NAME} &> /dev/null
	sleep 1s
	docker rm ${DB_CONTAINER_NAME} &> /dev/null
	sleep 1s
}

echo "CPU configuration:"
lscpu
echo "-----------------"
echo "Current huge page settings"
thp_value=`cat /sys/kernel/mm/transparent_hugepage/enabled |  cut -d '[' -f 2 | cut -d ']' -f 1`
echo "THP setting: ${thp_value}"
hugepages_total=`cat /proc/sys/vm/nr_hugepages`
echo "Huge page setting: ${hugepages_total}"
echo "-----------------"

sudo /bin/echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
sudo /bin/echo 0 > /proc/sys/vm/nr_hugepages

echo "Huge page settings for this run"
thp_value=`cat /sys/kernel/mm/transparent_hugepage/enabled |  cut -d '[' -f 2 | cut -d ']' -f 1`
echo "THP setting: ${thp_value}"
hugepages_total=`cat /proc/sys/vm/nr_hugepages`
echo "Huge page setting: ${hugepages_total}"
echo "-----------------"

if [ "${NATIVE_IMAGE}" -eq "0" ]; then
	checkJre
	checkJreWithJarmin
fi
checkJmeter
stop_db # this is to stop any previous db instances
start_db

if [ $# -gt "0" ];
then
	RESULTS_DIR=$1
fi

if [ -z "${RESULTS_DIR}" ]; then RESULTS_DIR="results"; fi
mkdir -p ${RESULTS_DIR} &> /dev/null

### JVM options ###

#TR_FlushProfilingBuffers=1
#JIT_OPTION="-Xjit:traceRelocatableDataDetailsRT,traceRelocatableDataRT,log=log,aotrtDebugLevel=30,rtLog=rtLog -Xaot:traceRelocatableDataDetailsRT,traceRelocatableDataRT,aotrtDebugLevel=30"
#export TR_IProfileMore=1
#export TR_DebugDLT=1

export JIT_LOG="${RESULTS_DIR}/jit.log"
JIT_VERBOSE_SETTING="verbose={compilePerformance,compileExclude,counts,inlining},vlog=${JIT_LOG},iprofilerVerbose,disableSuffixLogs"
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation"
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dltOptLevel=hot"
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,exclude={*Lambda*.*}"

#export JIT_SETTINGS="-Xjit:exclude={*Lambda*.*},${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"
#export JIT_SETTINGS="-Xjit:exclude={io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*},${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"
#export JIT_SETTINGS="-Xjit:disableAsyncCompilation,disableGuardedCountingRecompilation,{org/jboss/threads/EnhancedQueueExecutor\$ThreadBody.run()V}(count=0),{io/netty/channel/nio/NioEventLoop.run()V}(count=0),${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"
export JIT_SETTINGS="-Xjit:${JIT_VERBOSE_SETTING},${JIT_OPTIONS},exclude={*Lambda*.*,io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*,sun/nio/cs/UTF_8.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*,*DirectHandle.invokeExact_thunkArchetype*.*}"

### Jarmin controls ###

if [ "${NATIVE_IMAGE}" -eq "0" ]; then
	#export TR_RegisterForSigUsr=1
	export TR_JarminReductionMode="class"
	#export TR_DoNotRunJarmin=1
	#export TR_AllowCompileAfterJarmin=1
fi

echo "Settings for Jarmin:"
if [ ! -z ${TR_RegisterForSigUsr} ];
then
	echo "JarminReductionMode: ${TR_JarminReductionMode}"
	if [ ! -z ${TR_AllowCompileAfterJarmin} ]; then echo "AllowCompileAfterJarmin: ${TR_AllowCompileAfterJarmin}"; fi
else
	echo "TR_RegisterForSigUsr not defined"
fi

if [ -z ${ITERATIONS} ]; then
	ITERATIONS=1
fi

for i in `seq 1 ${ITERATIONS}`;
do
	echo "---------------------"
	echo "Starting iteration $i"
	./run_jmeter_load.sh "${RESULTS_DIR}/itr${i}"
	sleep 5s
done

stop_db

# restore THP and huge page settings
sudo /bin/echo "${thp_value}" > /sys/kernel/mm/transparent_hugepage/enabled
sudo /bin/echo "${hugepages_total}" > /proc/sys/vm/nr_hugepages

