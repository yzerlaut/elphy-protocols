COMMENT
Mod file that inject a static conductance of reversal potential muV
with current based synapses that 
Merged excitation and inhibition to be use with the dynamic clamp setup
negative weight is the flag for inhibition
Additional stationary current can be injected with the Icst variable
(Icst in pA !)
ENDCOMMENT

NEURON {
	POINT_PROCESS cExpSyn_with_static_cond
	RANGE tau, DrivingForce
	RANGE Gs, muV
	RANGE startI, stopI, stopI2, Icst, I0, I02
	RANGE stop_flag
	NONSPECIFIC_CURRENT i
}

UNITS {
	(nA) = (nanoamp)
	(mV) = (millivolt)
	(uS) = (microsiemens)
}

PARAMETER {
	tau = 5 (ms) <1e-9,1e9>
	DrivingForce = 30	(mV)
	muV = -60 (mV)
	Gs = 0.001 (uS)
	startI = 0 (ms) <1e-9,1e9>
	stopI = 1e8 (ms) <1e-9,1e9>
	stopI2 = 2e8 (ms) <1e-9,1e9>
	I0 = 0 (nA) : additional currrent input
	I02 = 0 (nA) : additional currrent input
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
}

INITIAL {
    ge=0
    gi=0
    Icst = 0 
    stop_flag = 0
    net_send(startI, 1) : turn on I0
    net_send(stopI, 2) : turn off I0 and turn on I02 
    net_send(stopI2, 3) : turn off I02 
}
    

BREAKPOINT {
    SOLVE state METHOD cnexp : exp decay for the conductances
    if (stop_flag==1) {
    	i=0
    } else { 
      i = (gi-ge)*DrivingForce + Gs*(v-muV)- Icst
    }
}


DERIVATIVE state {
    ge' = -ge/tau
    gi' = -gi/tau
}

NET_RECEIVE(weight (uS)) { 
    if (flag == 0) { : external event
	if (weight>0) { 
	    ge = ge + weight
	} 
	if (weight<0) { 
	    gi = gi - weight
	}
    }
    if (flag == 1) { : internal event, turn on I0
	Icst = I0
    }
    if (flag == 2) { : internal event, turn on I02
	Icst = I02
    }
    if (flag == 3) { : internal event, turn off I02
	Icst = 0
    }
}
