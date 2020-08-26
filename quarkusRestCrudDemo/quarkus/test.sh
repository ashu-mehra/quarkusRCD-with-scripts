#!/bin/bash

java HW &

sleep 1s
java_pid=`ps -ef | grep "java HW" |  grep -v grep | awk '{ print $2 }'`

trap "kill ${java_pid}" INT

kill -2 $$
wait
echo "After sending kill signal"
