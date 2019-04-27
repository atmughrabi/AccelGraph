import struct
from sys import argv
import numpy as np
import matplotlib.pyplot as plt 
import seaborn as sns
import collections
import pandas as pd


filename = argv[1]
typeedge = np.dtype([('src', np.uint32), ('dest', np.uint32), ('weight', np.uint32)])
sns.set(style="ticks")             


array= np.loadtxt(filename,dtype=typeedge)
x= array['src']
y= array['dest']
z= array['weight']

x=np.unique(x)
y=np.unique(y)
X,Y = np.meshgrid(x,y)

Z=z.reshape(len(y),len(x))

plt.pcolormesh(X,Y,Z, vmin=0, vmax=2)

plt.show()
