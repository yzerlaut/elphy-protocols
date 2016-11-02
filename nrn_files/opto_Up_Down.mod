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
	RANGE v_LP, Up_flag, UD_threshold, spike_threshold
	RANGE Up_Stim_Periodicity, Down_Stim_Periodicity
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

      : ---------------------------------------------------------------------
      : Let's compute the Real-Time Low-Pass-Filtered membrane potential
      : ---------------------------------------------------------------------
      : update with current v (with threshold for spikes)
      if (v<spike_threshold) { vec[0] = v }else {vec[0] = spike_threshold}
      : then shift all history
      FROM j=0 TO (N-2) {vec[(N-1)-j] = vec[(N-2)-j]} 
      v_LP = 0.0 : new Low pass filtered v
      FROM j=0 TO (N-1) {v_LP = v_LP + vec[j]*weights[j]} : compute

      if (V_TTL!=0) {
      : ---------------------------------------------------------------------
      : if we are stimulating, we do not want
      : that the evoked dynamics perturb the scheduled stimulation
      : ---------------------------------------------------------------------
	: so we just update the "state" flag 
	if (v_LP>UD_threshold) { Up_flag = 1} else { Up_flag = 0}
	: and we remove the stimulation if it is over
	if (t>up_time_start+Delay_for_Up_stim+Dur_for_Up_stim) { V_TTL=0 }
      }
      else { :================================================================
      : here we check for transitions and trigger stim when necessary
      :=======================================================================
      
	   : ---------------------------------------------------------------------
	   if (v_LP>UD_threshold) { : ==> We are in Up state
	   : ---------------------------------------------------------------------
		 if (Up_flag==0) { : We were in Down state -> transitions !
		 state_time_start = t : so we note the time of the transition
		 }
		 if (t>up_time_start+Delay_for_Up_stim)
		 
	    if (up_blank_flag==(Up_Stim_Periodicity-1)) {
	      up_blank_flag=0 : last was test, now reset to series of blank trials
	      } else {up_blank_flag=up_blank_flag+1} : increase blank/test variable
	    }
		 
	   
      }
      
      
      
	    
	    
	Up_flag = 1 : of course we set the flag to Up state

	: SHould we trigger a stimulation ?

	if ((t>up_time_start+Delay_for_Up_stim)
		&& (t<up_time_start+Delay_for_Up_stim+Dur_for_Up_stim)
		&& ((down_time_start-up_time_start)>Delay_for_Up_stim) ) {
	  : the condition ((down_time_start-up_time_start)>Delay_for_Up_stim)
	  : is used to monitor the fact that we did not have a transition before the stimulation should have started
	     if (up_blank_flag==(Up_Stim_Periodicity-1)) {
		 V_TTL = V0_TTL : test trial
	      } else { V_TTL = -V0_TTL/2. } : blank trials
	}
	
	
      : ---------------------------------------------------------------------
      } else {  : ==> We are in Down state
      : ---------------------------------------------------------------------
	if (Up_flag==1) { : means transition
	  down_time_start = t
	    if (down_blank_flag==0) {down_blank_flag=1} else {down_blank_flag=0} : switch of blank variable
	    }
	Up_flag = 0
      }
     else if ((t>down_time_start+Delay_for_Down_stim)
	  && (t<down_time_start+Delay_for_Down_stim+Dur_for_Down_stim)
	  && ((up_time_start-down_time_start)>Delay_for_Down_stim)) {
	       if (down_blank_flag==(Down_Stim_Periodicity-1)) {
		   V_TTL = V0_TTL : test trial
		} else { V_TTL = -V0_TTL/2. } : blank trials
	    }
     else {
	 V_TTL = 0. : no stim
      }
  }
