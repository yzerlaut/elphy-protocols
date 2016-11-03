COMMENT
Mod file that implements a real-time monitoring of Up and Down states dynamics
It low passes the Vm and do a simple upward and downward threshold detection
It sends a step-like signals for optogenetic stimulations at specific delays
of the Up and/or Down states
-------------------------------------------------------------------------
Written by Yann Zerlaut, Istituto Italiano di Tecnologia, October 2016
ENDCOMMENT

NEURON {
	POINT_PROCESS opto_Up_Down
	RANGE tau_LP, norm_factor
	RANGE V_TTL, V0_TTL
	RANGE vec
	RANGE v_LP, Up_flag, UD_threshold, spike_threshold
	RANGE Up_Stim_Periodicity, Down_Stim_Periodicity
	RANGE Delay_for_Up_stim, Delay_for_Down_stim
	RANGE Dur_for_Up_stim, Dur_for_Down_stim
	RANGE up_stimulation, down_stimulation
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
	spike_threshold = -30. (mV) : spike threshold
	UD_threshold = -60. (mV) : threshold for transitions between U&D
	Delay_for_Up_stim = 50. (ms)
	Delay_for_Down_stim = 100. (ms)
	Dur_for_Up_stim = 200. (ms)
	Dur_for_Down_stim = 200. (ms)
	Up_Stim_Periodicity = 3
	Down_Stim_Periodicity = 3
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
        up_stimulation
	down_stimulation
	norm_factor
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
      : =====================================================================
      : We compute the Real-Time Low-Pass-Filtered membrane potential
      : ---------------------------------------------------------------------
      : update with current v (with threshold for spikes)
      if (v<spike_threshold) { vec[0] = v }else {vec[0] = spike_threshold}
      : then shift all history
      FROM j=0 TO (N-2) {vec[(N-1)-j] = vec[(N-2)-j]} 
      v_LP = 0.0 : new Low pass filtered v
      FROM j=0 TO (N-1) {v_LP = v_LP + vec[j]*weights[j]} : compute

      : =====================================================================
      : Establishing the current state and tracking transitions
      : ---------------------------------------------------------------------
      if (v_LP>UD_threshold) { : ==> We are in Up state
      : ---------------------------------------------------------------------
	 if (Up_flag==0) { : We were in Down state -> transitions !
	    up_time_start = t : so we note the time of the transition
	   }
	 Up_flag = 1 : State update -> Up
      } else { : ==> We are in Down state
      : ---------------------------------------------------------------------
	 if (Up_flag==1) { : We were in Up state -> transitions !
	    down_time_start = t : so we note the time of the transition
	   }
	 Up_flag = 0 : State update -> Down
       }		 
      : =====================================================================
      : Triggering and removing stimulation
      : =====================================================================
      : if a new Down state did not appear, if the time conditions are matched and if we
      : were not stimulation, we start the stimulation
      : ---------------------------------------------------------------------
	if ((up_time_start>down_time_start) && (t>up_time_start+Delay_for_Up_stim) && (up_stimulation==0) && (t<=up_time_start+Delay_for_Up_stim+Dur_for_Up_stim)) {
	  up_stimulation = 1
	  : We decide whether that should ba a blamk trial or a test trial !
	    if (up_blank_flag==(Up_Stim_Periodicity-1)) {
	      up_blank_flag=0 : last was test, now reset to series of blank trials
	      V_TTL = V0_TTL
	      } else {
		 V_TTL = -1
		 up_blank_flag=up_blank_flag+1
	      } : increase blank/test variable
         }
      : =====================================================================
      : if a new Up state did not appear, if the time conditions are matched and if we
      : were not stimulation, we start the stimulation
      : ---------------------------------------------------------------------
	if ((down_time_start>up_time_start) && (t>down_time_start+Delay_for_Down_stim) && (down_stimulation==0) && (t<=down_time_start+Delay_for_Down_stim+Dur_for_Down_stim)) {
	  down_stimulation = 1
	  : We decide whether that should ba a blamk trial or a test trial !
	    if (down_blank_flag==(Down_Stim_Periodicity-1)) {
	      down_blank_flag=0 : last was test, now reset to series of blank trials
	      V_TTL = V0_TTL
	      } else {
		 V_TTL = -1
		 down_blank_flag=down_blank_flag+1
	      } : increase blank/test variable
         }
      : =====================================================================
      : N.B. if we are stimulating, we do not want that the evoked dynamics
      : perturb the scheduled stimulation, except if the stimulation should end !
      : ---------------------------------------------------------------------
      if ((up_stimulation==1) && (t>up_time_start+Delay_for_Up_stim+Dur_for_Up_stim)) {
	  V_TTL=0
	  up_stimulation = 0
        }
      if ((down_stimulation==1) && (t>down_time_start+Delay_for_Down_stim+Dur_for_Down_stim)) {
	  V_TTL=0
	  down_stimulation = 0
        }
}
