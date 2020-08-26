#!/usr/bin/env bash

# ./runpmap.sh $1 &> pmap.out &
# pmap -X $1 > pmap_0_users.out

#for USERS in 1 5 10 15 20 25 30 35 40
for USERS in 40
do
	echo "Runnning with $USERS users"
	for run in {1..2}
	do
		#wrk --threads=$USERS --connections=$USERS -d60s http://benchserver4G1:8080/fruits;
		numactl --physcpubind="16-31" --membind="1" ./wrk --threads=$USERS --connections=$USERS -d60s http://127.0.0.1:8080/fruits;
	done
#	date +%T >> pmap_${USERS}_users.out
#	pmap -X $1 >> pmap_${USERS}_users.out
done

#pkill -9 -x runpmap.sh

