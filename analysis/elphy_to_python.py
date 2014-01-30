from neo.io import ElphyIO
import numpy as np
import sys

File = str(sys.argv[1])
reader = ElphyIO(filename=File)


seg = reader.read_block(lazy=False, cascade=True)

sampling_freq = seg.segments[0].analogsignals[0].sampling_rate.magnitude.tolist()
tstart = seg.segments[0].analogsignals[0].t_start.magnitude.tolist()
tstop = seg.segments[0].analogsignals[0].t_stop.magnitude.tolist()
print sampling_freq, tstart, tstop

t = np.arange(tstart, tstop, 1./sampling_freq)
data = np.array(seg.segments[0].analogsignals, dtype='float32')

DATA = []
DATA.append(t)
for d in data:
    DATA.append(d)
    
