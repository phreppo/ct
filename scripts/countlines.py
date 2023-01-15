f = open('files/1gb')
lines = 0
for _ in f.readlines():
  lines += 1
print(lines)
