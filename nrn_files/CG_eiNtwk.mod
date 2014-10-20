COMMENT
Mod file to recreate a network input made of four synaptic populations :
1 ) excitatory conductance based
2) inhibitory conductance based
3) excitatory current  based
4) inhibitory current  based

Merged all populations to be use with the dynamic clamp setup the
above index should be set as the weight in Netcon as it is the flag
for each of respective event !
They all have equal weights, this is set here !
 
Symmetric reversal potential !
 
Additional stationary current can be injected with the Icst variable
(Icst in pA !)
ENDCOMMENT

NEURON {
    POINT_PROCESS ExpSyn_GC_eiNtwk
    RANGE Ts, Q
    RANGE muV_th, Driving_Force, Ee, Ei
    RANGE geC, giC, ge, gi
    RANGE I0, I1, I2, t1, t2, Icst
    RANGE stop_flag
    NONSPECIFIC_CURRENT i
}

UNITS {
	(nA) = (nanoamp)
	(mV) = (millivolt)
	(uS) = (microsiemens)
}

PARAMETER {
	Ts = 5 (ms) <1e-9,1e9>
	Driving_Force = 30	(mV)
	muV_th = -60	(mV)
	Ee = -30	(mV)
	Ei = -90	(mV)
	Q = 1e-10 (uS) <1e-12,1e3>
	t1 = 1e8 (ms) <1e-9,1e9>
	t2 = 1e8 (ms) <1e-9,1e9>
	I0 = 0 (nA) : additional currrent input starting at 0
	I1 = 0 (nA) : additional currrent input starting at t1
	I2 = 0 (nA) : additional currrent input starting at t2
}

ASSIGNED {
	v (mV)
	i (nA)
	Icst (nA)
	stop_flag
}

STATE {
    ge (uS)
    gi (uS)
    geC (uS)
    giC (uS)
}

INITIAL {
    ge=0
    gi=0
    geC=0
    giC=0
    stop_flag = 0
    Ee = muV_th+Driving_Force
    Ei =  muV_th-Driving_Force
    Icst = I0
    net_send(t1, -1)
    net_send(t2, -2)
}
    

BREAKPOINT {
    SOLVE state METHOD cnexp : exp decay for the conductances
    : stop_flag serves to shutdown the current
    i = (1-stop_flag)*(ge*(v-Ee)+gi*(v-Ei)+(giC-geC)*Driving_Force - Icst)
}

DERIVATIVE state {
    ge' = -ge/Ts
    gi' = -gi/Ts
    geC' = -geC/Ts
    giC' = -giC/Ts
}

NET_RECEIVE(weight (uS)) { 
    if (weight==1) { geC = geC + Q  } 
    if (weight==2) { giC = giC + Q   } 
    if (weight==3) { ge = ge + Q  } 
    if (weight==4) { gi = gi + Q } 
    if (flag==-1) { Icst = I1}
    if (flag==-2) { Icst = I2}
}
