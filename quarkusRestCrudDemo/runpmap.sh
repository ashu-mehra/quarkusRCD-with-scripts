#!/bin/bash

if [ $# -ne 1 ]; then
	echo "Insufficient argument. Please specify pid."
	exit 1;
fi

pid=$1
while true;
do
	time=`date +%T`
	memory=`pmap -X ${pid} | tail -n 1 | awk '{ print $2 " " $3 }'` # $2 is RSS, $3 is PSS
	echo "$time $memory"
	sleep 1s
done
