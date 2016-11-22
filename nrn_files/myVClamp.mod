TITLE myVClamp.mod
COMMENT
adapted by yann zerlaut, yann.zerlaut@gmail.com, 2013 CNRS, France and 2016 IIT, Italy
for the RTneuron-Simulation mode in Elphy
adapted from svclmp.mod // basically it enables to have a hodling set by the amplifier and not by NEURON !
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
	RANGE V0, rs, vc, i, V_CMD
	USEION ca READ cao WRITE cai 
	ELECTRODE_CURRENT i
}

UNITS {
	(nA) = (nanoamp)
	(pA) = (picoamp)
	(mV) = (millivolt)
	(uS) = (microsiemens)
}


PARAMETER {
    rs = 5 (megohm) <1e-9, 1e9>
    V0 = -70 (millivolt)
    I0 = 1000 (pA)
    I1 = 1 (nA)
    eca = 0 (mV)
}

ASSIGNED {
	v (mV)	: automatically v + vext when extracellular is present
	i (nA)
	vc (mV)
	cao (mV) : V_CMD is the command in voltage clamp, so Delta V !
	cai (pA)
}

BREAKPOINT {
	SOLVE icur METHOD after_cvode
	vstim()
	cai = -I0/I1*i
}

PROCEDURE icur() {
    i = (vc - v)/rs
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
    vc = V0+cao
    icur()
}
