# This file shows the square of the numbers from 0 to 5.

def squared(x=10):
    return x**2

for ii in range(6):
    print(ii, squared(ii))

print( squared() )
