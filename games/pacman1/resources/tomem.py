import sys

f = open(sys.argv[1]);

for line in f:
  outline = ""
  for n in line.split(','):
    outline += hex(int(n))[2:] + " "
  print outline
 
  

