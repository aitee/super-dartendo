

f = open(r'./dartendo/BattleCity.nes', 'rb')

bytes = f.read()
print '[',
first=True
for byte in bytes:
    if first==False:
        print ',',
    first = False
    print (str(ord(byte))),
print ']'


