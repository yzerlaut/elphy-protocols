NEURON {
	POINT_PROCESS Exp2Syn_eiNtwk
	RANGE tau1E,tauE, Ee, ge 
	RANGE tau1I,tauI, Ei, gi
	RANGE Ipico, stop_flag
	USEION ca READ cai : is the externally generated command !
	NONSPECIFIC_CURRENT i
}

UNITS {
	(nA) = (nanoamp)
	(mV) = (millivolt)
	(uS) = (microsiemens)
}

PARAMETER {
	tau1E = 0.1 (ms) <1e-9,1e9>
	tauE = 5 (ms) <1e-9,1e9>
	Ee = 0	(mV)
	tau1I = 0.2 (ms) <1e-9,1e9>
	tauI = 10 (ms) <1e-9,1e9>
	Ei = -80 (mV)
}

ASSIGNED {
	v (mV)
	i (nA)
	ge (uS)
	gi (uS)
	Ipico
	factorE
	factorI
	stop_flag
	cai (nA) : actually pA
}

STATE {
    Ae (uS)
    Be (uS)
    Ai (uS)
    Bi (uS)
}

INITIAL {
    LOCAL tpE,tpI
    :excitation
    if (tau1E/tauE > .9999) {
	tau1E = .9999*tauE
    }
    Ae = 0
    Be = 0
    tpE = (tau1E*tauE)/(tauE - tau1E) * log(tauE/tau1E)
    factorE = -exp(-tpE/tau1E) + exp(-tpE/tauE)
    factorE = 1/factorE
    :inhibition
    if (tau1I/tauI > .9999) {
	tau1I = .9999*tauI
    }
    Ai = 0
    Bi = 0
    tpI = (tau1I*tauI)/(tauI - tau1I) * log(tauI/tau1I)
    factorI = -exp(-tpI/tau1I) + exp(-tpI/tauI)
    factorI = 1/factorI
    Ipico = 0
    stop_flag = 0
}
    

BREAKPOINT {
    SOLVE state METHOD cnexp
    ge = Be - Ae
    gi = Bi - Ai
    if (stop_flag==1) {i=0} else { i = ge*(v-Ee)+gi*(v-Ei) - 0.001*cai}
    UNITSOFF
    Ipico = -1000*i
    UNITSON
}

DERIVATIVE state {
    Ae' = -Ae/tau1E
    Be' = -Be/tauE
    Ai' = -Ai/tau1I
    Bi' = -Bi/tauI
}

NET_RECEIVE(weight (uS)) { 
    if (weight>0) { 
	Ae = Ae + weight*factorE
	Be = Be + weight*factorE
    } 
    if (weight<0) { 
	Ai = Ai - weight*factorI
	Bi = Bi - weight*factorI
    }
}
