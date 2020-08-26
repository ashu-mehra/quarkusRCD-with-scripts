import sys
import re
import argparse
import os
import tempfile
from operator import itemgetter

def read_log_file(logfile):
   inlined_method_map = {}
   pattern = re.compile(r"#INL: ([0-9]*) methods inlined into ([[0-9A-Fa-f]*) (.*) @ .*")
   with open(logfile) as fp:
      for line in fp:
         match = pattern.match(line)
         if not match:
            continue
         method = match.group(3)
         inline_count = int(match.group(1))
         # print("method: {} count: {}".format(method, inline_count))
         if inlined_method_map.has_key(method):
            inlined_method_map[method] += inline_count
         else:
            inlined_method_map[method] = inline_count
   return inlined_method_map
   
def compare_maps(file1, map1, file2, map2, odir):
   file1_not_in_file2 = []
   file2_not_in_file1 = [] 
   file1_better_list = []
   file2_better_list = []
   common = []

   for method, count1 in map1.items():
      if map2.has_key(method):
         count2 = map2[method]
         if count1 > count2:
            file1_better_list.append((count1-count2, count1, count2, method))
         elif count2 > count1:
            file2_better_list.append((count2-count1, count1, count2, method))
         else:
            common.append((count1, method))
      else:
         file1_not_in_file2.append((count1, method))

   for method, count in map2.items():
      if not map1.has_key(method):
         file2_not_in_file1.append((count, method))

   file1_not_in_file2 = sorted(file1_not_in_file2, key = itemgetter(0), reverse=True)
   file2_not_in_file1 = sorted(file2_not_in_file1, key = itemgetter(0), reverse=True)
   file1_better_list = sorted(file1_better_list, key = itemgetter(0), reverse=True)
   file2_better_list = sorted(file2_better_list, key = itemgetter(0), reverse=True)

   total_inline_count = 0
   if bool(file1_not_in_file2):
      f = open(odir + "/file1-file2.txt", "w");
      f.write("methods in {} not in {}:\n".format(file1, file2))
      f.write("-" * 30)
      f.write("\n")
      for tuple in file1_not_in_file2:
         count = tuple[0]
         method = tuple[1]
         f.write("{:>4} | {}\n".format(count, method))
         total_inline_count += count
      f.write("-" * 30)
      f.write("\n")
      f.write("total: methods={}, inline count={}\n".format(len(file1_not_in_file2), total_inline_count))
      f.close()

   total_inline_count = 0
   if bool(file2_not_in_file1):
      f = open(odir + "/file2-file1.txt", "w");
      f.write("methods in {} not in {}:\n".format(file2, file1))
      f.write("-" * 30)
      f.write("\n")
      for tuple in file2_not_in_file1:
         count = tuple[0]
         method = tuple[1]
         f.write("{:>4} | {}\n".format(count, method))
         total_inline_count += count
      f.write("-" * 30)
      f.write("\n")
      f.write("total: methods={}, inline count={}\n".format(len(file2_not_in_file1), total_inline_count))
      f.close()

   total_diff = 0
   if bool(file1_better_list):
      f = open(odir + "/file1_better_file2.txt", "w");
      sum_diff = sum([tuple[0] for tuple in file1_better_list])
      sum_count1 = sum([tuple[1] for tuple in file1_better_list])
      sum_count2 = sum([tuple[2] for tuple in file1_better_list])
      f.write("methods with better inlining in {} than {}\n".format(file1, file2))
      f.write("-" * 30)
      f.write("\n");
      f.write("diff | inline count in file1 | inline count in file2 | method\n");
      f.write("-" * 30)
      f.write("\n");
      for tuple in file1_better_list:
         diff = tuple[0]
         count1 = tuple[1]
         count2 = tuple[2]
         method = tuple[3]
         total_diff += diff
         f.write("{:>4} | {:>4} | {:>4} | {}\n".format(diff, count1, count2, method))
      f.write("-" * 30)
      f.write("\n")
      f.write("{:>4} | {:>4} | {:>4}\n".format(sum_diff, sum_count1, sum_count2))
      f.write("total methods={}\n".format(len(file1_better_list)))
      f.close()

   total_diff = 0
   if bool(file2_better_list):
      f = open(odir + "/file2_better_file1.txt", "w");
      sum_diff = sum([tuple[0] for tuple in file2_better_list])
      sum_count1 = sum([tuple[1] for tuple in file2_better_list])
      sum_count2 = sum([tuple[2] for tuple in file2_better_list])
      f.write("methods with better inlining in {} than {}\n".format(file2, file1))
      f.write("-" * 30)
      f.write("\n");
      f.write("diff | inline count in file1 | inline count in file2 | method\n");
      f.write("-" * 30)
      f.write("\n");
      for tuple in file2_better_list:
         diff = tuple[0]
         count1 = tuple[1]
         count2 = tuple[2]
         method = tuple[3]
         total_diff += diff
         f.write("{:>4} | {:>4} | {:>4} | {}\n".format(diff, count1, count2, method))
      f.write("-" * 30)
      f.write("\n")
      f.write("{:>4} | {:>4} | {:>4}\n".format(sum_diff, sum_count1, sum_count2))
      f.write("total methods={}\n".format(len(file2_better_list)))
      f.close()

   total_inlining = 0
   if bool(common):
      f = open(odir + "/common.txt", "w");
      f.write("methods common in two files\n")
      f.write("-" * 30)
      f.write("\n")
      f.write("inline count | method\n")
      f.write("-" * 30)
      f.write("\n");
      for tuple in common:
         total_inlining += tuple[0]
         f.write("{:>4} | {}\n".format(tuple[0], tuple[1]))
      f.write("-" * 30)
      f.write("\n")
      f.write("total: methods={}, total inlining={}\n".format(len(common), total_inlining))
      f.close()

def main():
   parser = argparse.ArgumentParser()
   parser.add_argument("jitlog1", help="first log file")
   parser.add_argument("jitlog2", help="second log file")
   parser.add_argument("-o", "--odir", help="output directory for the generated files")
   args = parser.parse_args();
   
   log1 = args.jitlog1
   log2 = args.jitlog2
   if args.odir:
       if not os.path.isdir(args.odir):
           os.mkdir(args.odir)
       odir = args.odir
   else:
       temp_dir = TemporaryDirectory()
       odir = temp_dir.name
   results_dir = sys.argv[3]
   read_log_file(log1)
   inlined_method_map1 = read_log_file(log1)
   inlined_method_map2 = read_log_file(log2)
   compare_maps(log1, inlined_method_map1, log2, inlined_method_map2, odir)
   print("Results dir: {}".format(odir))

if __name__ == '__main__':
   main()
