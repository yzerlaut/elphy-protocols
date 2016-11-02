import time
import matplotlib.pylab as plt
import numpy as np
from scipy import polyfit

# path = "D:\\Yann\\DATA\\"+time.strftime("%Y")+"_"+time.strftime("%m")\
#   +"_"+time.strftime("%d")+"\\"
path = "/home/yann/experiments/DATA/"+time.strftime("%Y")+"_"+time.strftime("%m")\
   +"_"+time.strftime("%d")+"/"
import os.path

plt.figure(num=None, figsize=(7, 11.69), dpi=100)
plt.suptitle(time.strftime("%c"))

pp = plt.subplot2grid((8,3),(1,0), rowspan=3, colspan=3)
pp.set_xlabel(r"injected current ($\mu$A)")
pp.set_ylabel(r"electric field (mV/mm)")
tt = plt.subplot2grid((8,3),(5,0), rowspan=4, colspan=3)
tt.axis('off')

field_min = [-20, -15, -10, -5, -2.5, -1]
field_max = [20, 15, 10, 5, 2.5, 1]

for ii in range(len(field_min)):
    tt.annotate(str(field_min[ii])+' mV/mm', (0.4, 1.08-ii*0.1), fontsize = 10,
                 xycoords="axes fraction", va="center", ha="center",
                 bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
for ii in range(len(field_max)):
    tt.annotate(str(field_max[ii])+' mV/mm', (0.4, -0.08+ii*0.1), fontsize = 10,
                 xycoords="axes fraction", va="center", ha="center",
                 bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))

if os.path.exists(path+'conduct.txt'):
    ax = plt.subplot2grid((8,3),(0,1))
    ax.axis('off')
    plt.annotate("CONDUCTIVITY ?", (0.4, 1.), color='k', fontsize = 13,
                 xycoords="axes fraction", va="center", ha="center",
                 bbox=dict(boxstyle="round, pad=1", fc="lightgray"))
    [i, v] = np.loadtxt(path+'conduct.txt')
    pp.plot(i, v, 'kD')
    p = polyfit(i, v, 1)
    pp.plot(i, p[1]+p[0]*i, 'k-', lw=5, alpha=.5)    
    
    plt.annotate("["+str(round(p[0],2))+" $I_{inj}$ +"+str(round(p[1],2))+"] mV/mm",
                (-0.3, 0.2), fontsize=12, color='k', xycoords="axes fraction")

    for ii in range(len(field_min)):
        tt.annotate(str(round((field_min[ii]-p[1])/p[0],1))+' $\mu$A',
                    (0.7, 1.08-ii*0.1), fontsize = 12, color='k',
                 xycoords="axes fraction", va="center", ha="center")
    for ii in range(len(field_max)):
        tt.annotate(str(round((field_max[ii]-p[1])/p[0],1))+' $\mu$A',
                    (0.7, -0.08+ii*0.1), fontsize = 12, color='k',
                    xycoords="axes fraction", va="center", ha="center")
else:
    print "Filename problem, conduct.txt, no such file existing !"
    
        
plt.savefig(path+'c-f-relationship.pdf')

