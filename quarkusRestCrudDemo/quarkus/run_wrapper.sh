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

#JIT_OPTIONS="disableAsyncCompilation,{io/netty/handler/codec/http/HttpObjectDecoder.decode(*}(traceFull,traceInlining,log=HttpObjectDecoder.decode.log)"

#JIT_OPTIONS="disableAsyncCompilation,dontDowngradeToCold,disableConservativeColdInlining,disableConservativeInlining,bigCalleeThreshold=600,bigCalleeHotOptThreshold=600,bigCalleeScorchingOptThreshold=600,inlineVeryLargeCompiledMethods,disableMethodIsCold"
JIT_OPTIONS="disableAsyncCompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,bigCalleeThreshold=750,bigCalleeHotOptThreshold=750,bigCalleeScorchingOptThreshold=750,scratchSpaceLimit=524288"
#JIT_OPTIONS="disableAsyncCompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,bigCalleeThreshold=750,bigCalleeHotOptThreshold=750,bigCalleeScorchingOptThreshold=750,{org/hibernate/boot/registry/selector/internal/StrategySelectorBuilder.addDialects(*}(traceFull,traceInlining,log=StrategySelectorBuilder.addDialects.log)"
#JIT_OPTIONS="disableAsyncCompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,{io/netty/handler/codec/http/HttpObjectDecoder.decode(*}(traceFull,traceInlining,log=HttpObjectDecoder.decode.log)"
#JIT_OPTIONS="disableAsyncCompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,disableConservativeColdInlining,disableConservativeInlining,bigCalleeThreshold=750,bigCalleeHotOptThreshold=750,bigCalleeScorchingOptThreshold=750,inlineVeryLargeCompiledMethods,disableMethodIsCold"
#JIT_OPTIONS="disableAsyncCompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,disableConservativeColdInlining,disableConservativeInlining,bigCalleeThreshold=750,bigCalleeHotOptThreshold=750,bigCalleeScorchingOptThreshold=750,inlineVeryLargeCompiledMethods,{io/agroal/pool/ConnectionFactory.recoveryProperties(*}(traceFull,traceInlining,log=ConnectionFactory.recoveryProperties.log)"
#JIT_OPTIONS="disableAsyncCompilation,dontDowngradeToCold,{io/netty/handler/codec/http/HttpObjectDecoder.decode(*}(traceFull,traceInlining,log=HttpObjectDecoder.decode.log)"

#JIT_OPTIONS="disableAsyncCompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics"

#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,exclude={*\$Lambda*.*,io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*,java/net/Inet4AddressImpl.lookupAllHostAddr*,sun/nio/cs/UTF_8\$Encoder.implReplaceWith*,sun/nio/cs/UTF_8\$Encoder.isLegalReplacement*,sun/nio/cs/UTF_8.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*}"

# allow all compilations except those in classnotfound methods, lambda classes and not identified by jarmin
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,exclude={*\$Lambda*.*,io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*,java/net/Inet4AddressImpl.lookupAllHostAddr*,sun/nio/cs/UTF_8\$Encoder.implReplaceWith*,sun/nio/cs/UTF_8\$Encoder.isLegalReplacement*,sun/nio/cs/UTF_8.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*}"

# disable all phase3 compilations: JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,inhibitRecompilation,disableMethodHandleThunks,disableDynamicLoopTransfer,exclude={*\$Lambda*.*,io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*,sun/nio/cs/UTF_8\$Encoder.implReplaceWith*,sun/nio/cs/UTF_8\$Encoder.isLegalReplacement*,sun/nio/cs/UTF_8\$Encoder.<init>*,sun/nio/cs/UTF_8.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*,java/lang/Thread.yield*,java/net/Inet4AddressImpl.lookupAllHostAddr*,java/net/PlainSocketImpl.socketConnect*,java/net/PlainSocketImpl.socketCreate*,sun/nio/ch/FileDispatcherImpl.writev0*}"

# disable phase 3 compilations except MethodHandleThunks
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,inhibitRecompilation,disableDynamicLoopTransfer,exclude={*\$Lambda*.*,io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*,sun/nio/cs/UTF_8\$Encoder.implReplaceWith*,sun/nio/cs/UTF_8\$Encoder.isLegalReplacement*,sun/nio/cs/UTF_8\$Encoder.<init>*,sun/nio/cs/UTF_8.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*,java/lang/Thread.yield*,java/net/Inet4AddressImpl.lookupAllHostAddr*,java/net/PlainSocketImpl.socketConnect*,java/net/PlainSocketImpl.socketCreate*,sun/nio/ch/FileDispatcherImpl.writev0*}"

# disable phase 3 compilations except classnotfound methods 
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,inhibitRecompilation,disableMethodHandleThunks,disableDynamicLoopTransfer,exclude={*\$Lambda*.*,sun/nio/cs/UTF_8\$Encoder.implReplaceWith*,sun/nio/cs/UTF_8\$Encoder.isLegalReplacement*,sun/nio/cs/UTF_8\$Encoder.<init>*,sun/nio/cs/UTF_8.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*,java/lang/Thread.yield*,java/net/Inet4AddressImpl.lookupAllHostAddr*,java/net/PlainSocketImpl.socketConnect*,java/net/PlainSocketImpl.socketCreate*,sun/nio/ch/FileDispatcherImpl.writev0*}"

# disable phase 3 compilations except jni methods 
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,inhibitRecompilation,disableMethodHandleThunks,disableDynamicLoopTransfer,exclude={*\$Lambda*.*,io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*,sun/nio/cs/UTF_8\$Encoder.implReplaceWith*,sun/nio/cs/UTF_8\$Encoder.isLegalReplacement*,sun/nio/cs/UTF_8\$Encoder.<init>*,sun/nio/cs/UTF_8.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*}"

# disable phase 3 compilations except lambda methods
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,inhibitRecompilation,disableMethodHandleThunks,disableDynamicLoopTransfer,exclude={io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*,sun/nio/cs/UTF_8\$Encoder.implReplaceWith*,sun/nio/cs/UTF_8\$Encoder.isLegalReplacement*,sun/nio/cs/UTF_8\$Encoder.<init>*,sun/nio/cs/UTF_8.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*,java/lang/Thread.yield*,java/net/Inet4AddressImpl.lookupAllHostAddr*,java/net/PlainSocketImpl.socketConnect*,java/net/PlainSocketImpl.socketCreate*,sun/nio/ch/FileDispatcherImpl.writev0*}"

# disable phase 3 compilations except not identified methods
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,inhibitRecompilation,disableMethodHandleThunks,disableDynamicLoopTransfer,exclude={*\$Lambda*.*,io/netty/util/concurrent/PromiseCombiner.*,io/netty/util/concurrent/PromiseCombiner\$1.*,java/util/AbstractList\$ListItr.*,java/util/concurrent/atomic/Striped64\$Cell.*,java/util/concurrent/ConcurrentLinkedQueue\$Itr.*,sun/nio/ch/IOVecWrapper.*,java/lang/Thread.yield*,java/net/Inet4AddressImpl.lookupAllHostAddr*,java/net/PlainSocketImpl.socketConnect*,java/net/PlainSocketImpl.socketCreate*,sun/nio/ch/FileDispatcherImpl.writev0*}"

# disable phase 3 compilations except MethodHandleThunks and classnotfound methods
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,inhibitRecompilation,disableDynamicLoopTransfer,exclude={*\$Lambda*.*,sun/nio/cs/UTF_8\$Encoder.implReplaceWith*,sun/nio/cs/UTF_8\$Encoder.isLegalReplacement*,sun/nio/cs/UTF_8\$Encoder.<init>*,sun/nio/cs/UTF_8.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*,java/lang/Thread.yield*,java/net/Inet4AddressImpl.lookupAllHostAddr*,java/net/PlainSocketImpl.socketConnect*,java/net/PlainSocketImpl.socketCreate*,sun/nio/ch/FileDispatcherImpl.writev0*}"

# disable phase 3 compilations except MethodHandleThunks and classnotfound methods and jni methods
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,inhibitRecompilation,disableDynamicLoopTransfer,exclude={*\$Lambda*.*,java/net/Inet4AddressImpl.lookupAllHostAddr*,sun/nio/cs/UTF_8\$Encoder.implReplaceWith*,sun/nio/cs/UTF_8\$Encoder.isLegalReplacement*,sun/nio/cs/UTF_8\$Encoder.<init>*,sun/nio/cs/UTF_8.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*}"

# disable phase 3 compilations except MethodHandleThunks and classnotfound methods and jni methods and lambda methods
# JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,inhibitRecompilation,disableDynamicLoopTransfer,exclude={java/net/Inet4AddressImpl.lookupAllHostAddr*,sun/nio/cs/UTF_8\$Encoder.implReplaceWith*,sun/nio/cs/UTF_8\$Encoder.isLegalReplacement*,sun/nio/cs/UTF_8\$Encoder.<init>*,sun/nio/cs/UTF_8.*,*GeneratedConstructorAccessor*.*,*GeneratedMethodAccessor*.*}"

# disable phase 3 compilations except MethodHandleThunks and classnotfound methods and jni methods and lambda methods and not identified methods
#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableBlockFrequencyBasedInlinerHeuristics,inhibitRecompilation,disableDynamicLoopTransfer"

#JIT_OPTIONS="disableAsyncCompilation,disableGuardedCountingRecompilation,dontDowngradeToCold,disableProfiledInlining,disableConservativeColdInlining,disableConservativeInlining,bigCalleeThreshold=600,bigCalleeHotOptThreshold=600,bigCalleeScorchingOptThreshold=600,inlineVeryLargeCompiledMethods,disableMethodIsCold"

export JIT_SETTINGS="-Xjit:${JIT_VERBOSE_SETTING},${JIT_OPTIONS}"


### Jarmin controls ###

if [ "${NATIVE_IMAGE}" -eq "0" ]; then
	export TR_RegisterForSigUsr=1
	export TR_JarminReductionMode="class"
	#export TR_DoNotRunJarmin=1
	export TR_AllowCompileAfterJarmin=1
	#export TR_LoadExtraClassesBeforeCompiling=1
	#export TR_DisableFurtherCompilationUsingFlag=1
	export TR_WarmInlineAdjustCallGraphMaxCutOff=5000
	export TR_FlushProfilingBuffers=1
	export TR_IProfileMore=1
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

