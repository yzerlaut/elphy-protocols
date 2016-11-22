
# ######################################################
# Testing the Isyn feedback loop
# ######################################################

from neuron import h as nrn
nrn.dt = 0.05
nrn('create soma')
nrn.soma.L, nrn.soma.diam = 79.8, 79.8
nrn.soma.insert("pas")
nrn.soma.insert("ca_ion")
nrn.soma.e_pas = -70.
nrn.soma.g_pas = 5e-5
nrn.soma.insert("hh_hippoc")
# nrn.soma.insert("WangBuszaki")

UD = nrn.Isyn_feedback_for_opto(.5, sec=nrn.soma)
UD.up_stimulation = 0
UD.down_stimulation = -1 
UD.upward_threshold = 50
UD.downward_threshold = -200
UD.CMD_delay = -30.
UD.CMD_dur = 100.
stim = nrn.Exp2Syn_eiNtwk(.5, sec=nrn.soma)
vclamp = nrn.myVClamp(.5, sec=nrn.soma)
vclamp.rs = 5.

for i in range(20):
    UD.delay_vec[i] = 30.
    if i%2==1:
        UD.cmd_vec[i] = 10.

nsE = nrn.NetStim(.5, sec=nrn.soma)
nsE.start, nsE.number, nsE.noise, nsE.interval = 0, 1e10, 1, 2.
ncE = nrn.NetCon(nsE, stim)
ncE.delay = 0
nsI = nrn.NetStim(.5, sec=nrn.soma)
nsI.start, nsI.number, nsI.noise, nsI.interval = 0, 1e10, 1, 1.
ncI = nrn.NetCon(nsI, stim)
ncI.delay = 0
ncE.weight[0] = 0.004
ncI.weight[0] = -0.003

Qe_up, Qe_down = 0.004, 0.0001
Qi_up, Qi_down = -0.003,  -0.0032
ncE.weight[0] = Qe_up
ncI.weight[0] = Qi_up

V, up_flag, Isyn, i_LP, vlp, vttl, t = [], [], [], [], [], [], []

nrn.finitialize(-70.)
while nrn.t<2000:
    t.append(nrn.t)
    V.append(nrn.soma.v)
    vlp.append(nrn.soma.cao-70.)
    Isyn.append(nrn.soma.cai)
    i_LP.append(UD.i_LP)
    vttl.append(UD.V_LASER)
    up_flag.append(UD.Up_flag)
    nrn.fadvance()
    if (nrn.t%400)<200:
        ncE.weight[0] = (Qe_up-ncE.weight[0])*Qe_up/(Qe_up-Qe_down) - (Qe_down-ncE.weight[0])*Qe_down/(Qe_up-Qe_down)
        ncI.weight[0] = (Qi_up-ncI.weight[0])*Qi_up/(Qi_up-Qi_down) - (Qi_down-ncI.weight[0])*Qi_down/(Qi_up-Qi_down)

import matplotlib.pylab as plt
fig, ax= plt.subplots(3, figsize=(7,5))
ax[0].plot(t, Isyn, 'k-', label='raw data')
ax[0].plot(t, i_LP, 'r-', label='raw data')
ax[0].plot([t[0], t[-1]], [UD.upward_threshold,UD.upward_threshold], 'k:')
ax[0].plot([t[0], t[-1]], [UD.downward_threshold,UD.downward_threshold], 'k:')
ax[1].plot(t, V, 'k-', label='raw data')
ax[1].plot(t, vlp, 'r-', label='raw data')
ax[2].plot(up_flag)
ax[2].plot(t, vttl, 'r-', label='TTL signal')
plt.show()

# # ######################################################
# # Testing the Vm feedback loop
# # ######################################################

# from neuron import h as nrn
# nrn.dt = 1/500.*1e3
# nrn('create soma')
# nrn.soma.insert("pas")
# nrn.soma.e_pas = -70.
# nrn.soma.g_pas = 1e-5
# nrn.soma.insert("hh")
# ic = nrn.IClamp(.5, sec=nrn.soma)
# ic.amp = 10.
# ic.dur = 700.
# ic.delay = 200.
# UD = nrn.opto_Up_Down(.5, sec=nrn.soma)
# UD.tau_LP = 30.

# up_flag, v, vlp, vttl = [], [], [], []

# nrn.finitialize(-70.)
# while nrn.t<310:
#     nrn.fadvance()
#     v.append(nrn.soma.v)
#     vlp.append(UD.v_LP)
#     vttl.append(UD.V_TTL)
#     up_flag.append(UD.Up_flag)
# print(UD.norm_factor)

# import matplotlib.pylab as plt
# fig, ax= plt.subplots(3, figsize=(7,5))
# ax[0].plot(v, 'b-', label='raw data')
# ax[0].plot(vlp, 'g--', label='RT low-pass')
# ax[0].legend()
# ax[1].plot(up_flag)
# ax[2].plot(vttl, 'r-', label='TTL signal')
# plt.show()

