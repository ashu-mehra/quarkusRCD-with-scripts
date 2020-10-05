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

start_db() {
	DB_CONTAINER_NAME="postgres-quarkus-rest-http-crud"

	docker run --network=host -d --cpuset-cpus=0,1,4,5 --cpuset-mems=0 --ulimit memlock=-1:-1 -it --memory-swappiness=0 --name ${DB_CONTAINER_NAME} -e POSTGRES_USER=restcrud -e POSTGRES_PASSWORD=restcrud -e POSTGRES_DB=rest-crud -p 5432:5432 postgres:10.5
}

stop_db() {
	DB_CONTAINER_NAME="postgres-quarkus-rest-http-crud"

	docker stop ${DB_CONTAINER_NAME} &> /dev/null
	sleep 1s
	docker rm ${DB_CONTAINER_NAME} &> /dev/null
	sleep 1s
}

checkJre
checkJreWithJarmin
stop_db # this is to stop any previous db instances
start_db

sleep 2s

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
JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation"
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dltOptLevel=hot"
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,exclude={*Lambda*.*}"

#export JIT_SETTINGS="-Xjit:exclude={*Lambda*.*},${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"
#export JIT_SETTINGS="-Xjit:exclude={io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*},${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"
#export JIT_SETTINGS="-Xjit:disableAsyncCompilation,disableGuardedCountingRecompilation,{org/jboss/threads/EnhancedQueueExecutor\$ThreadBody.run()V}(count=0),{io/netty/channel/nio/NioEventLoop.run()V}(count=0),${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"
export JIT_SETTINGS="-Xjit:${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"


### Jarmin controls ###

export TR_RegisterForSigUsr=1
export TR_JarminReductionMode="class"
#export TR_DoNotRunJarmin=1
export TR_AllowCompileAfterJarmin=1

echo "Settings for Jarmin:"
if [ ! -z ${TR_RegisterForSigUsr} ];
then
	echo "JarminReductionMode: ${TR_JarminReductionMode}"
	if [ ! -z ${TR_AllowCompileAfterJarmin} ]; then echo "AllowCompileAfterJarmin: ${TR_AllowCompileAfterJarmin}"; fi
else
	echo "TR_RegisterForSigUsr not defined"
fi

./run_jmeter_load.sh "${RESULTS_DIR}"

stop_db

