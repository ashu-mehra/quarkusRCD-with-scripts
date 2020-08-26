#!/bin/bash

for urls in `seq 2 2`;
do
	echo "Using ${urls} url"
	export NUM_URLS=${urls}
	for req in `seq 1 10`;
	do
		export NUM_REQUESTS=${req}
		echo "Starting iterations for ${NUM_REQUESTS} requests"
		./run_iterations /root/ashu/quarkus_jarmin/jarmin_phase2_no_further_comp_${urls}urls_${req}requests 1
		sleep 5s
	done
done
