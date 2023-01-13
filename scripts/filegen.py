import random
file_path = input('insert the path of the file you want to generate: ')
exponent = input('insert the size of the file you want to generate: ')
s = ''
f = open(file_path, 'w')
for _ in range(2 ** int(exponent)):
  s += random.choice(['a', 'b', '\n'])
f.write(s)