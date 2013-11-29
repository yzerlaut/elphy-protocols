import time
import matplotlib.pylab as plt
import numpy as np
from scipy import polyfit

# path = "D:\\Yann\\DATA\\"+time.strftime("%Y")+"_"+time.strftime("%m")\
#   +"_"+time.strftime("%d")+"\\"
path = "/home/yann/experiments/DATA/"+time.strftime("%Y")+"_"+time.strftime("%m")\
   +"_"+time.strftime("%d")+"/"
import os.path

#plt.xkcd()

plt.figure(num=None, figsize=(7, 11.69), dpi=100)

pp = plt.subplot2grid((8,3),(1,0), rowspan=3, colspan=3)
pp.set_xlabel(r"injected current ($\mu$A)")
pp.set_ylabel(r"electric field (mV/mm)")
tt = plt.subplot2grid((8,3),(5,0), rowspan=4, colspan=3)
tt.axis('off')


if os.path.exists(path+'low_conduct.txt'):
    ax = plt.subplot2grid((8,3),(0,0))
    ax.axis('off')
    plt.annotate("LOW \n CONDUCTIVITY", (0.5, 0.5), color='k', fontsize = 16,
                 xycoords="axes fraction", va="center", ha="center",
                 bbox=dict(boxstyle="round, pad=1", fc="b"))

    [i, v] = np.loadtxt(path+'low_conduct.txt')
    pp.plot(i, v, 'bD')
    p = polyfit(i, v, 1)
    pp.plot(i, p[1]+p[0]*i, 'b-', lw=3, alpha=.5)    
    pp.annotate("["+str(round(p[0],2))+" $I_{inj}$ "+str(round(p[1],2))+"] mV/mm",
                (0.1, 0.9), fontsize=14, color='b', xycoords="axes fraction")
    
    # ax = plt.subplot2grid((8,3),(0,1))
    # ax.axis('off')
    # plt.annotate("Middle \n Conductivity", (0.5, 0.5), fontsize = 16,
    #              xycoords="axes fraction", va="center", ha="center",
    #              bbox=dict(boxstyle="round, pad=1", fc="g"))
    
    # ax = plt.subplot2grid((8,3),(0,2))
    # ax.axis('off')
    # plt.annotate("High \n Conductivity", (0.5, 0.5), fontsize = 16,
    #              xycoords="axes fraction", va="center", ha="center",
    #              bbox=dict(boxstyle="round, pad=1", fc="r"))


field_min = [-20, 15, -10, -5, -2.5]
for ii in range(len(field_min)):
    tt.annotate(str(field_min[ii])+' mV/mm', (0.1, 1.05-ii*0.1), fontsize = 10,
                 xycoords="axes fraction", va="center", ha="center",
                 bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# tt.annotate('-15 mV/mm', (0.1, 0.95), fontsize = 10,
#                  xycoords="axes fraction", va="center", ha="center",
#                  bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# tt.annotate('-10 mV/mm', (0.1, 0.85), fontsize = 10,
#                  xycoords="axes fraction", va="center", ha="center",
#                  bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# tt.annotate('-5 mV/mm', (0.1, 0.75), fontsize = 10,
#                  xycoords="axes fraction", va="center", ha="center",
#                  bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# tt.annotate('-2.5 mV/mm', (0.1, 0.65), fontsize = 10,
#                  xycoords="axes fraction", va="center", ha="center",
#                  bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# tt.annotate('-1mV/mm', (0.1, 0.55), fontsize = 10,
#                  xycoords="axes fraction", va="center", ha="center",
#                  bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# tt.annotate('20 mV/mm', (0.1, -0.15), fontsize = 10,
#                  xycoords="axes fraction", va="center", ha="center",
#                  bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# tt.annotate('15 mV/mm', (0.1, -0.05), fontsize = 10,
#                  xycoords="axes fraction", va="center", ha="center",
#                  bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# tt.annotate('10 mV/mm', (0.1, 0.05), fontsize = 10,
#                  xycoords="axes fraction", va="center", ha="center",
#                  bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# tt.annotate('5 mV/mm', (0.1, 0.15), fontsize = 10,
#                  xycoords="axes fraction", va="center", ha="center",
#                  bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# tt.annotate('2.5 mV/mm', (0.1, 0.25), fontsize = 10,
#                  xycoords="axes fraction", va="center", ha="center",
#                  bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# tt.annotate('1mV/mm', (0.1, 0.35), fontsize = 10,
#                  xycoords="axes fraction", va="center", ha="center",
#                  bbox=dict(boxstyle="round, pad=.7", fc="lightgray"))
# for ii in range(7):
#     tt.arrow(0.2, ii*0.1+0.55, 0.1, 0.)
#     tt.arrow(0.2, ii*0.1-0.2, 0.1, 0.)

plt.savefig(path+'c-f-relationship.pdf')

