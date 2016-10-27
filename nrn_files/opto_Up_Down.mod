COMMENT
Mod file that implements a real-time monitoring of Up and Down states dynamics
It low passes the Vm and do a simple upward and downward threshold detection
-------------------------------------------------------------------------
Written by Yann Zerlaut, Istituto Italiano di Tecnologia, October 2016
ENDCOMMENT

NEURON {
	POINT_PROCESS opto_Up_Down
	RANGE tau_LP, norm_factor
	RANGE V_TTL, V0_TTL
	RANGE vec
	RANGE v_LP, Up_flag, UD_threshold
	RANGE Delay_for_Up_stim, Delay_for_Down_stim
	RANGE Dur_for_Up_stim, Dur_for_Down_stim
	NONSPECIFIC_CURRENT i
}

CONSTANT {N = 100}

UNITS {
	(mV) = (millivolt)
	(nA) = (nanosecond)
	(kHz) = (kilohertz)
}

PARAMETER {
	tau_LP = 20. (ms) <1e-9,1e9>:Time constant for Online Low Pass Filtering
	V0_TTL = 5. (mV) <1e-9,1e9> : TTL trigger
	UD_threshold = -60. (mV) : threshold for transitions between U&D
	Delay_for_Up_stim = 50. (ms)
	Delay_for_Down_stim = 100. (ms)
	Dur_for_Up_stim = 200. (ms)
	Dur_for_Down_stim = 200. (ms)
	norm_factor
}

ASSIGNED {
	v (mV)
	v_LP (mV)
	V_TTL (mV)
	weights[100]
	vec[100]
	Up_flag
	up_time_start (ms)
	down_time_start (ms)
	i (nA)
        up_blank_flag
	down_blank_flag
}

INITIAL {
    printf("================================================== \n")
    printf("For tau_LP=%g , and dt=%g , you get: \n", tau_LP, dt)
    printf("        N=%g , It should be ~ 20 \n", tau_LP/dt)
    printf("================================================== \n")
    FROM j=0 TO (N-1) {vec[j] = -70}
    FROM j=0 TO (N-1) {weights[j] = exp(-1.0*j*dt/tau_LP)}
    norm_factor = 0
    FROM j=0 TO (N-1) {norm_factor = norm_factor + weights[j]}
    FROM j=0 TO (N-1) {weights[j] = weights[j]/norm_factor}
    v_LP = 0
    V_TTL = 0
    up_blank_flag = 0
    down_blank_flag = 1
}
    

BREAKPOINT {
      vec[0] = v : update with current v
      FROM j=0 TO (N-2) {vec[(N-1)-j] = vec[(N-2)-j]} : shift all history
      v_LP = 0.0 : new Low pass filtered v
      FROM j=0 TO (N-1) {v_LP = v_LP + vec[j]*weights[j]} : compute
      norm_factor = vec[0]
      if (v_LP>UD_threshold) {
	if (Up_flag==0) { : means transition
	    up_time_start = t
	    if (up_blank_flag==0) {up_blank_flag=1} else {up_blank_flag=0} : switch of blank variable
	    }
	Up_flag = 1
      } else { 
	if (Up_flag==1) { : means transition
	  down_time_start = t
	    if (down_blank_flag==0) {down_blank_flag=1} else {down_blank_flag=0} : switch of blank variable
	    }
	Up_flag = 0
      }
	  if ((t>up_time_start+Delay_for_Up_stim) && (t<up_time_start+Delay_for_Up_stim+Dur_for_Up_stim) && ((down_time_start-up_time_start)>Delay_for_Up_stim) ) {
	  : the condition ((down_time_start-up_time_start)>Delay_for_Up_stim)
	  : is used to monitor the fact that we did not have a transition before the stimulation should have started
	  if (up_blank_flag==1) {
	     V_TTL = -V0_TTL/2.
	    }
	  else {
	   V_TTL = V0_TTL
	  }
	}
	if ((t>down_time_start+Delay_for_Down_stim) && (t<down_time_start+Delay_for_Down_stim+Dur_for_Down_stim) && ((up_time_start-down_time_start)>Delay_for_Down_stim)) {
	    if (down_blank_flag==1) {
	       V_TTL = -V0_TTL/2.
	      }
	    else {
	       V_TTL = V0_TTL
	      }
	  }
	else {
       V_TTL = 0.
	 }
  }
