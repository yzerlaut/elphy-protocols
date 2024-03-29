COMMENT
modified by yann zerlaut (UNIC lab, Destexhe team 2014) from
: $Id: netstim.mod 1305 2006-04-10 21:14:26Z hines $
and from the APcount.mod file (it's a mix of them)

basically the "interval" variable of Netstim becomes dependent on the
output firing of the post-synaptic neuron
Each "spike_number_for_update" spikes we update "interval"
thanks to the firing rate calculated from this number of spikes

The calculus of interval is performed within the "check()" function
---
The thing is that we need to start to sample the output firing rate 
frequency before we start to send presynaptic events
ENDCOMMENT

NEURON	{ 
  POINT_PROCESS NetStim_from_self_spike
  RANGE interval, number, start, synapses_number
  RANGE bound_min_interval, bound_max_interval
  RANGE noise, interval_increment, max_duration
  RANGE n, thresh, time, firing
  RANGE spike_number_for_update, nspike_last_freq
  POINTER donotuse
}

UNITS {
    (mV) = (millivolt)
}

PARAMETER {
    interval	= 1e4 (ms) <1e-9,1e9>: time between spikes (msec)
    number	= 1e8 <0,1e9>	: number of spikes (independent of noise)
    start		= 50 (ms)	: start of first spike
    noise		= 1 <0,1>	: amount of randomness (0.0 - 1.0)
    n
    thresh = -20 (mV)
    time (ms)
    synapses_number = 1 : number of synapses of the population
    spike_number_for_update = 5 : by default, 5 spikes to have an update
    bound_min_interval = 5e-6 (ms) : 200 Hz
    bound_max_interval = 100 (ms) : 0.1 Hz
    max_duration = 3000 (ms) 
}

ASSIGNED {
    v (mV)
    firing
    space
    event (ms)
    on
    ispike
    donotuse
    nspike_last_freq : number of spikes until last freq update
    interval_increment
}

PROCEDURE seed(x) {
    set_seed(x)
}


INITIAL {
    n = 0
    nspike_last_freq = 0
    firing = 0
    check()
    interval_increment = 0
    on = -1 : tenatively off
    ispike = 0
    if (noise < 0) {
	noise = 0
    }
    if (noise > 1) {
	noise = 1
    }
    if (start >= 0 && number > 0) {
	net_send(start, 3)
    }
}	

BREAKPOINT {
    SOLVE check METHOD after_cvode
}


PROCEDURE check() {
    
    if (v >= thresh && !firing) {
	firing = 1
	n = n+1
	interval_increment = interval_increment+t-time
	
	: now update of the interval variable
	if (n-nspike_last_freq>=spike_number_for_update && t>start) {
	    interval = bounded_interval_update(interval_increment/spike_number_for_update)
	    nspike_last_freq = n
	    interval_increment = 0
	}
	time = t
    }  : /* END OF SPIKING CONDITION */

    if (firing && v < thresh && t > time) {
	firing = 0
    }
    if (t-time>max_duration) {interval=interval+bound_min_interval}
}


PROCEDURE init_sequence(t(ms)) {
    if (number > 0) {
	on = 1
	event = 0
	ispike = 0
    }
}

FUNCTION invl(mean (ms)) (ms) {
    if (mean <= 0.) {
	mean = .01 (ms) : I would worry if it were 0.
    }
    if (noise == 0) {
	invl = mean
    }else{
	invl = (1. - noise)*mean + noise*mean*erand()
    }
}

FUNCTION bounded_interval_update(interval) {
    if ( (interval>=bound_min_interval) && (interval<=bound_max_interval) ) {
        bounded_interval_update = interval
    } else if (interval<=bound_min_interval) {
        bounded_interval_update = bound_min_interval
    } else if (interval>=bound_max_interval) {
        bounded_interval_update = bound_max_interval
    }
}

VERBATIM
double nrn_random_pick(void* r);
void* nrn_random_arg(int argpos);
ENDVERBATIM

FUNCTION erand() {
VERBATIM
	if (_p_donotuse) {
		/*
		:Supports separate independent but reproducible streams for
		: each instance. However, the corresponding hoc Random
		: distribution MUST be set to Random.negexp(1)
		*/
		_lerand = nrn_random_pick(_p_donotuse);
	}else{
ENDVERBATIM
		: the old standby. Cannot use if reproducible parallel sim
		: independent of nhost or which host this instance is on
		: is desired, since each instance on this cpu draws from
		: the same stream
		erand = exprand(1)
VERBATIM
	}
ENDVERBATIM
}

PROCEDURE noiseFromRandom() {
VERBATIM
 {
	void** pv = (void**)(&_p_donotuse);
	if (ifarg(1)) {
		*pv = nrn_random_arg(1);
	}else{
		*pv = (void*)0;
	}
 }
ENDVERBATIM
}

PROCEDURE next_invl() {
	if (number > 0) {
		event = invl(interval/synapses_number) : WE ADD SYNAPSES NUMBER
	}
	if (ispike >= number) {
		on = 0
	}
}

NET_RECEIVE (w) {
	if (flag == 0) { : external event
		if (w > 0 && on == 0) { : turn on spike sequence
			: but not if a netsend is on the queue
			init_sequence(t)
			: randomize the first spike so on average it occurs at
			: noise*interval (most likely interval is always 0)
			next_invl()
			: WE ADD synapses number TO STANDARD NETSTIM
			event = event - interval/synapses_number*(1. - noise)
			net_send(event, 1)
		}else if (w < 0) { : turn off spiking definitively
			on = 0
		}
	}
	if (flag == 3) { : from INITIAL
	    nspike_last_freq = n : we actually start the calculus of the freq
	    interval = bounded_interval_update((1e-9+start)/n) : new interval 
	    
		if (on == -1) { : but ignore if turned off by external event
			init_sequence(t)
			net_send(0, 1)
		}
	}
	if (flag == 1 && on == 1) {
		ispike = ispike + 1
		net_event(t)
		next_invl()
		if (on == 1) {
			net_send(event, 1)
		}
	}
}

COMMENT
Presynaptic spike generator
---------------------------

This mechanism has been written to be able to use synapses in a single
neuron receiving various types of presynaptic trains.  This is a "fake"
presynaptic compartment containing a spike generator.  The trains
of spikes can be either periodic or noisy (Poisson-distributed)

Parameters;
   noise: 	between 0 (no noise-periodic) and 1 (fully noisy)
   interval: 	mean time between spikes (ms)
   number: 	number of spikes (independent of noise)

Written by Z. Mainen, modified by A. Destexhe, The Salk Institute

Modified by Michael Hines for use with CVode
The intrinsic bursting parameters have been removed since
generators can stimulate other generators to create complicated bursting
patterns with independent statistics (see below)

Modified by Michael Hines to use logical event style with NET_RECEIVE
This stimulator can also be triggered by an input event.
If the stimulator is in the on==0 state (no net_send events on queue)
 and receives a positive weight
event, then the stimulator changes to the on=1 state and goes through
its entire spike sequence before changing to the on=0 state. During
that time it ignores any positive weight events. If, in an on!=0 state,
the stimulator receives a negative weight event, the stimulator will
change to the on==0 state. In the on==0 state, it will ignore any ariving
net_send events. A change to the on==1 state immediately fires the first spike of
its sequence.

ENDCOMMENT

