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

thp_value=`cat /sys/kernel/mm/transparent_hugepage/enabled |  cut -d '[' -f 2 | cut -d ']' -f 1`
echo "THP setting: ${thp_value}"
hugepages_total=`cat /proc/sys/vm/nr_hugepages`
echo "Huge page setting: ${hugepages_total}"
echo "-----------------"

sudo /bin/echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
sudo /bin/echo 0 > /proc/sys/vm/nr_hugepages

# export DO_PERF_PROFILING=1
export NATIVE_IMAGE=0

if [ "${NATIVE_IMAGE}" -eq "0" ]; then
	checkJre
	checkJreWithJarmin
fi
#stop_db # this is to stop any previous db instances
#start_db

if [ $# -gt "0" ];
then
	RESULTS_DIR=$1
fi

if [ -z "${RESULTS_DIR}" ]; then RESULTS_DIR="results"; fi
mkdir -p ${RESULTS_DIR} &> /dev/null


### JVM options ###

#TR_FlushProfilingBuffers=1
#JIT_OPTION="-Xjit:traceRelocatableDataDetailsRT,traceRelocatableDataRT,log=log,aotrtDebugLevel=32,rtLog=rtLog -Xaot:traceRelocatableDataDetailsRT,traceRelocatableDataRT,aotrtDebugLevel=30"
#export TR_IProfileMore=1
#export TR_DebugDLT=1

export JIT_LOG="${RESULTS_DIR}/jit.log"

JIT_VERBOSE_SETTING="verbose={compilePerformance,compileExclude,counts,inlining},vlog=${JIT_LOG},iprofilerVerbose,disableSuffixLogs"

#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableProfiledInlining"
JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics"
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,exclude={*Lambda*.*,io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*,sun/nio/cs/UTF_8.*,sun/nio/cs/UTF_8\$*.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*,DirectHandle.invokeExact_thunkArchetype*.*},{io/vertx/ext/web/impl/RouterImpl.handle(Ljava/lang/Object;)V}(optLevel=warm)"
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableProfiledInlining,disableConservativeColdInlining,disableConservativeInlining,bigCalleeThreshold=600,bigCalleeHotOptThreshold=600,bigCalleeScorchingOptThreshold=600,inlineVeryLargeCompiledMethods,{org/jboss/resteasy/core/ServerResponseWriter.getDefaultContentType*}(traceInlining,log=ServerResponseWriter.getDefaultContentType.log),{io/netty/buffer/PooledByteBufAllocator\$PoolThreadLocalCache.initialValue*}(traceInlining,log=PoolThreadLocalCache.initialValue.log),{org/hibernate/cfg/PropertyContainer.collectPersistentAttributesUsingClassLevelAccessType*}(traceInlining,log=PropertyContainer.collectPersistentAttributesUsingClassLevelAccessType.log),{org/hibernate/loader/Loader.initializeEntitiesAndCollections*}(traceInlining,log=Loader.initializeEntitiesAndCollections.log)"
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableProfiledInlining,disableConservativeColdInlining,disableConservativeInlining,bigCalleeThreshold=600,bigCalleeHotOptThreshold=600,bigCalleeScorchingOptThreshold=600,inlineVeryLargeCompiledMethods,disableMethodIsCold"
#JIT_OPTIONS="scratchSpaceLimit=524288,disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableProfiledInlining,disableConservativeColdInlining,disableConservativeInlining,bigCalleeThreshold=600,bigCalleeHotOptThreshold=600,bigCalleeScorchingOptThreshold=600,inlineVeryLargeCompiledMethods,disableMethodIsCold,{org/jboss/resteasy/core/ServerResponseWriter.getDefaultContentType*}(traceFull,traceBlockFrequencyGeneration,traceInlining,log=ServerResponseWriter.getDefaultContentType.log),{io/netty/buffer/PooledByteBufAllocator\$PoolThreadLocalCache.initialValue*}(traceFull,traceBlockFrequencyGeneration,traceInlining,log=PoolThreadLocalCache.initialValue.log),{org/hibernate/cfg/PropertyContainer.collectPersistentAttributesUsingClassLevelAccessType*}(traceFull,traceBlockFrequencyGeneration,traceInlining,log=PropertyContainer.collectPersistentAttributesUsingClassLevelAccessType.log),{org/hibernate/loader/Loader.initializeEntitiesAndCollections*}(traceFull,traceBlockFrequencyGeneration,traceInlining,log=Loader.initializeEntitiesAndCollections.log),{org/hibernate/loader/Loader.executeQueryStatement*}(traceFull,traceBlockFrequencyGeneration,traceInlining,log=Loader.executeQueryStatement.log)"
# fails: JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableProfiledInlining,disableConservativeColdInlining,disableConservativeInlining,bigCalleeThreshold=600,inlineVeryLargeCompiledMethods"
# fails: JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableProfiledInlining,disableConservativeInlining,bigCalleeThreshold=600,inlineVeryLargeCompiledMethods"
# fails: JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableConservativeInlining,bigCalleeThreshold=600,inlineVeryLargeCompiledMethods"
# fails: JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,disableConservativeInlining,bigCalleeThreshold=600,inlineVeryLargeCompiledMethods"
# fails: JIT_OPTIONS="disableAsyncCompilation,disableConservativeInlining,bigCalleeThreshold=600,inlineVeryLargeCompiledMethods"
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dltOptLevel=hot,scratchSpaceLimit=524288"
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,exclude={*Lambda*.*}"

#export JIT_SETTINGS="-Xjit:exclude={*Lambda*.*},${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"
#export JIT_SETTINGS="-Xjit:exclude={io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*},${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"
#export JIT_SETTINGS="-Xjit:disableAsyncCompilation,disableGuardedCountingRecompilation,{org/jboss/threads/EnhancedQueueExecutor\$ThreadBody.run()V}(count=0),{io/netty/channel/nio/NioEventLoop.run()V}(count=0),${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"
export JIT_SETTINGS="-Xjit:${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"


### Jarmin controls ###

if [ "${NATIVE_IMAGE}" -eq "0" ]; then
	export TR_RegisterForSigUsr=1
	export TR_JarminReductionMode="class"
	#export TR_DoNotRunJarmin=1
	#export TR_AllowCompileAfterJarmin=1
	#export TR_DisableFurtherCompilationUsingFlag=1
fi

echo "Settings for Jarmin:"
if [ ! -z ${TR_RegisterForSigUsr} ];
then
	echo "JarminReductionMode: ${TR_JarminReductionMode}"
	if [ ! -z ${TR_AllowCompileAfterJarmin} ]; then echo "AllowCompileAfterJarmin: ${TR_AllowCompileAfterJarmin}"; fi
else
	echo "TR_RegisterForSigUsr not defined"
fi

./run_jmeter_load.sh "${RESULTS_DIR}"

#stop_db
# restore THP and huge page settings
sudo /bin/echo "${thp_value}" > /sys/kernel/mm/transparent_hugepage/enabled
sudo /bin/echo "${hugepages_total}" > /proc/sys/vm/nr_hugepages

