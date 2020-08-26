#!/bin/bash

while IFS= read -r line; do
	addr=`echo $line | cut -d ' ' -f 2`
	size=`echo $line | cut -d ' ' -f 3`
	grep ${addr} active_allocations.txt >/dev/null
	if [ $? -ne 0 ]; then
		echo "mmap: ${addr} ${size} glibc (null) 0" >> active_allocations.txt
	fi
done < active_mmap.txt 
