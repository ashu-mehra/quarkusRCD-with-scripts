import sys
import array
import re

class Iteration:
   def __init__(self, index, base_dir_name):
      self.index = index
      self.base_dir = base_dir_name
      self.phases = []

   def get_phase(self, phase_index):
      return self.phases[phase_index]

   def set_phases(self, phases):
      self.phases = phases
   
   def generate_stats(self, showDetails):
      firstPhase = True
      for phase in self.phases:
         if showDetails:
            phase.show_details(self.base_dir + "." + str(self.index) + "/" + "compile_stats", not firstPhase)
         else:
            phase.show_stats(self.base_dir + "." + str(self.index) + "/" + "compile_stats", not firstPhase)
         firstPhase = False

class Phase:
   def __init__(self, index):
      self.index = index
      self.methods = []
      self.recompiledMethods = []
      self.compiles = {}
      self.recompiles = {}

   def get_compiles(self):
      return self.compiles

   def get_recompiles(self):
      return self.recompiles

   def add_compilation(self, level, method, line):
      new_method = False
 
      if method not in self.methods:
         self.methods.append(method)
         new_method = True 
      elif method not in self.recompiledMethods:
         self.recompiledMethods.append(method)

      if new_method:
         if not self.compiles.has_key(level):
            self.compiles[level] = []
         self.compiles[level].append((method, line))
      else:
         if not self.recompiles.has_key(level):
            self.recompiles[level] = []
         self.recompiles[level].append((method, line))

   def add_recompilation(self, level, method, line):
      if method not in self.recompiledMethods:
         self.recompiledMethods.append(method)
      if not self.recompiles.has_key(level):
         self.recompiles[level] = []
      self.recompiles[level].append((method, line))

   def is_method_compiled(self, method):
      return method in self.methods

   def show_details(self, file="", append=False):
      if file != "":
         original_stdout = sys.stdout
         if append:
            sys.stdout = open(file, "a")
         else:
            sys.stdout = open(file, "w")

      print("Phase {} compilations".format(self.index))
      print("-" * 15)

      for level, list in self.compiles.items():
         print("level: {}\n".format(level))
         for entry in list:
            print("\t{}".format(entry[0]))

      print("-" * 15)
      print("Phase {} recompilations:".format(self.index))
      print("-" * 15)

      for level, list in self.recompiles.items():
         print("level: {}\n".format(level))
         for entry in list:
            print("\t{}".format(entry[0]))

      print("-" * 15)
      self.show_stats(file, True)
      sys.stdout = original_stdout 

   def show_stats(self, file="", append=False):
      if file != "":
         original_stdout = sys.stdout
         if append:
            sys.stdout = open(file, "a")
         else:
            sys.stdout = open(file, "w")

      print("Phase {} stats:".format(self.index))
      print("-" * 15)

      total_compiles = 0
      for level, list in self.compiles.items():
         print("\tlevel: {}, compilations: {}".format(level, len(list)))
         total_compiles += len(list)
      print("\ttotal compiles: {}".format(total_compiles))

      total_recompiles = 0
      for level, list in self.recompiles.items():
         print("\tlevel: {}, recompilations: {}".format(level, len(list)))
         total_recompiles += len(list)
      print("\ttotal recompiles: {}".format(total_recompiles))
      print("compiles+recompiles: {}".format(total_compiles + total_recompiles))

      print("")
      sys.stdout = original_stdout 

def add_to_phase(method, level, compileLine, phase, previousPhases):
   for p in previousPhases:
      if p.is_method_compiled(method):
         phase.add_recompilation(level, method, compileLine)
         return
   phase.add_compilation(level, method, compileLine)

def process_log_file(logFile, phase, phases):
   pattern = re.compile(r"\+ \((.*)\) (.*) @ .*")
   with open(logFile) as fp:
      for line in fp:
         match = pattern.match(line)
         if not match:
            continue
         level = match.group(1)
         method = match.group(2)
         if level == "AOT load":
            continue;
         #print("level: {}\t method: {}".format(level, method))
         add_to_phase(method, level, line, phase, phases)
   phases.append(phase)

def add_compiles(compiles_per_level, total_compiles_per_level):
   for level, list in compiles_per_level.items():
      if total_compiles_per_level.has_key(level):
         total_compiles_per_level[level] += len(list)
      else:
         total_compiles_per_level[level] = len(list)
      total_compiles_per_level["total"] += len(list)

def print_compiles_per_level(total_compiles_per_level, num_iterations, is_recompilation=False):
   for level, total in total_compiles_per_level.items():
      if is_recompilation:
         print("\tlevel: {}, recompilations: {}".format(level, total/num_iterations))
      else:
         print("\tlevel: {}, compilations: {}".format(level, total/num_iterations))
   
def summarize(iterations_list):
   for phase in range(0, 3):
      print("Phase {} stats:".format(phase+1))
      print("-" * 15)
      total_compiles_per_level = {"total": 0}
      total_recompiles_per_level = {"total": 0}
      for iteration in iterations_list:
         add_compiles(iteration.get_phase(phase).get_compiles(), total_compiles_per_level)
         add_compiles(iteration.get_phase(phase).get_recompiles(), total_recompiles_per_level)
      print_compiles_per_level(total_compiles_per_level, len(iterations_list))
      print_compiles_per_level(total_recompiles_per_level, len(iterations_list), True)
           
def main():
   showDetails = False 
   optionsDone = False 

   for i, arg in enumerate(sys.argv):
      if (i == 0):
         continue
      logFile = ""
      if not optionsDone:
         if arg.startswith("-"):
            if arg == "-detail" or arg == "-d":
               showDetails = True 
            elif arg == "-summarize" or arg == "-s":
               multiple_iterations=True
               if (i+1 == len(sys.argv)):
                  print("Base directory name is missing\n")
                  sys.exit(1)
               if (i+2 == len(sys.argv)):
                  print("Number of iterations is missing\n")
                  sys.exit(1)
               base_dir_name=sys.argv[i+1]
               iterations=sys.argv[i+2]
               break
         else:
            optionsDone = True
            last_option_index = i
      if optionsDone:
         if arg.startswith("-"):
            print("Option {} specified at incorrect location\n".format(arg))
            sys.exit(1)

   if multiple_iterations:
      iterations_list = []
      for i in range(1, int(iterations)+1):
         iteration = Iteration(i, base_dir_name)
         phases = []
         for phase_index in range(1, 4):
            phase = Phase(phase_index)
            logFile=base_dir_name + "." + str(i) + "/" + "jit.log.phase" + str(phase_index)
            print("Processing file: {} for iteration {}, phase {}\n".format(logFile, i, phase_index))
            process_log_file(logFile, phase, phases)
         iteration.set_phases(phases)
         iteration.generate_stats(showDetails)
         iterations_list.append(iteration)
      summarize(iterations_list)
   else:
      phases = []
      for index in range(last_option_index, len(sys,argv)):
         logFile = sys.argv[index]
         phase = Phase(index - last_option_index + 1)
         process_log_file(logfile, phase, phases)
         phases.append(phase)
      for phase in phases:
         if showDetails:
            phase.show_details()
         else:
            phase.show_stats()

if __name__ == '__main__':
   main()
