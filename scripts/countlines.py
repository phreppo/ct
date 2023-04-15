import sys
if len(sys.argv) != 2:
  print('Must call with exactly one argument')
  sys.exit(1)
else:
  filename = sys.argv[1]
  f = open(filename)
  lines = 0
  for _ in f.readlines():
    lines += 1
  print(lines)
