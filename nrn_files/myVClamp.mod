TITLE VClamp.mod
COMMENT
adapted by yann zerlaut : zerlaut@unic.cnrs-gif.fr
for the RTneuron-Simulation mode in Elphy
adapted from svclmp.mod
see the comments below
-----------------------------------------------------------------------
Single electrode Voltage clamp with three levels.
Clamp is on at time 0, and off at time
dur1+dur2+dur3. When clamp is off the injected current is 0.
The clamp levels are amp1, amp2, amp3.
i is the injected current, vc measures the control voltage)
Do not insert several instances of this model at the same location in order to
make level changes. That is equivalent to independent clamps and they will
have incompatible internal state values.
The electrical circuit for the clamp is exceedingly simple:
vc ---'\/\/`--- cell
        rs

Note that since this is an electrode current model v refers to the
internal potential which is equivalent to the membrane potential v when
there is no extracellular membrane mechanism present but is v+vext when
one is present.
Also since i is an electrode current,
positive values of i depolarize the cell. (Normally, positive membrane currents
are outward and thus hyperpolarize the cell)
ENDCOMMENT

NEURON {
	POINT_PROCESS myVClamp
	ELECTRODE_CURRENT i
	RANGE del, Vamp, rs, vc, i, Ipico
}

UNITS {
	(nA) = (nanoamp)
	(mV) = (millivolt)
	(uS) = (microsiemens)
}


PARAMETER {
    rs = 1 (megohm) <1e-9, 1e9>
    del = 0 (ms)
}

ASSIGNED {
	v (mV)	: automatically v + vext when extracellular is present
	i (nA)
	vc (mV)
	Vamp (mV)
	on
	Ipico
}

INITIAL {
	on = 0
}

BREAKPOINT {
	SOLVE icur METHOD after_cvode
	vstim()
	UNITSOFF
	Ipico = 1000*i
	UNITSON
}

PROCEDURE icur() {
	if (on) {
		i = (vc - v)/rs
	}else{
		i = 0
	}
}

COMMENT
The SOLVE of icur() in the BREAKPOINT block is necessary to compute
i=(vc - v(t))/rs instead of i=(vc - v(t-dt))/rs
This is important for time varying vc because the actual i used in
the implicit method is equivalent to (vc - v(t)/rs due to the
calculation of di/dv from the BREAKPOINT block.
The reason this works is because the SOLVE statement in the BREAKPOINT block
is executed after the membrane potential is advanced.

It is a shame that vstim has to be called twice but putting the call
in a SOLVE block would cause playing a Vector into vc to be off by one
time step.
ENDCOMMENT

PROCEDURE vstim() {
    
	on = 1
	at_time(del)

	if (t >= del) {
		vc = Vamp
	}
	icur()
}
