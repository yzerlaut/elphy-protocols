from neuron import h as nrn
nrn.dt = 1/500.*1e3
nrn('create soma')
nrn.soma.insert("pas")
nrn.soma.e_pas = -70.
nrn.soma.g_pas = 1e-5
nrn.soma.insert("hh")
ic = nrn.IClamp(.5, sec=nrn.soma)
ic.amp = 10.
ic.dur = 700.
ic.delay = 200.
UD = nrn.opto_Up_Down(.5, sec=nrn.soma)
UD.tau_LP = 30.

up_flag, v, vlp, vttl = [], [], [], []

nrn.finitialize(-70.)
while nrn.t<310:
    nrn.fadvance()
    v.append(nrn.soma.v)
    vlp.append(UD.v_LP)
    vttl.append(UD.V_TTL)
    up_flag.append(UD.Up_flag)
print(UD.norm_factor)

import matplotlib.pylab as plt
fig, ax= plt.subplots(3, figsize=(7,5))
ax[0].plot(v, 'b-', label='raw data')
ax[0].plot(vlp, 'g--', label='RT low-pass')
ax[0].legend()
ax[1].plot(up_flag)
ax[2].plot(vttl, 'r-', label='TTL signal')
plt.show()
