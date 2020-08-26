import sys
import array
import re

def main():
	jittedMethodMap = {}
	recompiledMethodList = []
	filepath = sys.argv[1]

	print("Using file={}".format(filepath))
	pattern = re.compile(r"\+ \(.*\) (.*) @ .*")
	totalCompilations = 0
	recompilationCount = 0
	with open(filepath) as fp:
		for line in fp:
			match = pattern.match(line)
			if not match:
				continue
			totalCompilations += 1
			method = match.group(1)
			# print "method: ", method
			if jittedMethodMap.has_key(method):
				recompilationCount += 1
				if method not in recompiledMethodList:
					recompiledMethodList.append(method)
			jittedMethodMap[method] = line

	print "methods:"
	for method in jittedMethodMap:
		print "\t", method

	print "recompiled methods:"
	for method in recompiledMethodList:
		print "\t", method

	print "-------------------\n"	
	print "compilations:", totalCompilations
	print "unique compilations:", len(jittedMethodMap)
	print "recompilations:", recompilationCount
	print "methods recompiled:", len(recompiledMethodList)
	print "Recompiled methods:"

if __name__ == '__main__':
    main()
