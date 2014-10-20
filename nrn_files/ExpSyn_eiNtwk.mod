COMMENT
Mod file to recreate a network input made of two synaptic populations :
and excitatory and inhibitory one
Merged excitation and inhibition to be use with the dynamic clamp setup
negative weight is the flag for inhibition
Additional stationary current can be injected with the Icst variable
(Icst in pA !)
ENDCOMMENT

NEURON {
	POINT_PROCESS ExpSyn_eiNtwk
	RANGE tauE, Ee, ge 
	RANGE tauI, Ei, gi
	RANGE startI, stopI, Icst
	RANGE stop_flag
	NONSPECIFIC_CURRENT i
}

UNITS {
	(nA) = (nanoamp)
	(mV) = (millivolt)
	(uS) = (microsiemens)
}

PARAMETER {
	tauE = 5 (ms) <1e-9,1e9>
	Ee = 0	(mV)
	tauI = 5 (ms) <1e-9,1e9>
	Ei = -80 (mV)
	startI = 0 (ms) <1e-9,1e9>
	stopI = 1e8 (ms) <1e-9,1e9>
	Icst = 0 (nA) : additional currrent input
}

ASSIGNED {
	v (mV)
	i (nA)
	stop_flag
}

STATE {
    ge (uS)
    gi (uS)
}

INITIAL {
    ge=0
    gi=0
    stop_flag = 0
}
    

BREAKPOINT {
    SOLVE state METHOD cnexp : exp decay for the conductances
    
    if (stop_flag==1) {
	i=0
    } else { 
	if (t < stopI && t >= startI) { 
	    i = ge*(v-Ee)+gi*(v-Ei) - Icst
	} else {
	    i = ge*(v-Ee)+gi*(v-Ei)
	}
    }
}

DERIVATIVE state {
    ge' = -ge/tauE
    gi' = -gi/tauI
}

NET_RECEIVE(weight (uS)) { 
    if (weight>0) { 
	ge = ge + weight
    } 
    if (weight<0) { 
	gi = gi - weight
    }
}
