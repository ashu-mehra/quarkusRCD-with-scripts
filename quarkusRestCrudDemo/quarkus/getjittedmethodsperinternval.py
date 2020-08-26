import sys
import array

def main():
	jittedMethodCount = array.array('i', [0])
	filepath = sys.argv[1]
	interval = int(sys.argv[2]) * 1000

	print("Using file={}, interval={} secs".format(filepath, interval))
	currentSize = 0
	with open(filepath) as fp:
		for line in fp:
			time = int(line)
			bucket = 0
			#print "time=", time 
			if (time % interval == 0):
				bucket = time/interval;
			else:
				bucket = time/interval + 1;
			if (bucket >= len(jittedMethodCount)):
				while currentSize < bucket:
					jittedMethodCount.append(0)
					currentSize += 1
				jittedMethodCount.append(1)
			else:
				jittedMethodCount[bucket] += 1

	count = 0
	for i in jittedMethodCount:
		print count/1000,",",i
		count += interval

if __name__ == '__main__':
    main()
