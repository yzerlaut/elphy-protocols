COMMENT
Mod file that implements a real-time monitoring of Up and Down states dynamics
in the Voltage-Clamp mode
I relies on the amplitude of the fluctuations at the baseline level (e.g. ~-70mV)
It sends a step-like signals for optogenetic stimulations at specific delays
of the Up and/or Down states 
-------------------------------------------------------------------------
Written by Yann Zerlaut, Istituto Italiano di Tecnologia, October 2016
ENDCOMMENT

NEURON {
	POINT_PROCESS Isyn_feedback_for_opto
        RANGE norm_factor, subsampling_freq
	RANGE V_LASER, CMD_delay, CMD_dur
	RANGE vec, stim_vec, delay_vec, duration_vec, amplitude_vec, cmd_vec
	RANGE i_up, i_down
	RANGE up_transition_vec, down_transition_vec
	RANGE i_LP, Up_flag, upward_threshold, downward_threshold
	RANGE Up_Stim_Periodicity, Down_Stim_Periodicity
	RANGE Delay_for_Up_stim, Delay_for_Down_stim
	RANGE Dur_for_Up_stim, Dur_for_Down_stim
	RANGE up_stimulation, down_stimulation
	USEION ca READ cai WRITE cao : "cao" is the V-clamp Command and "cai" is the synaptic current !
}

CONSTANT {
  N = 100
  Nvec = 2000
}

UNITS {
	(mV) = (millivolt)
	(pA) = (picoamp)
	(kHz) = (kilohertz)
}

PARAMETER {
	subsampling_freq = 1. (kilohertz) : subsampling frequency
	downward_threshold = -55. (mV) : threshold for transitions between U&D
	upward_threshold = -65. (mV) : threshold for transitions between U&D
	Delay_for_Up_stim = 50. (ms)
	Delay_for_Down_stim = 100. (ms)
	Dur_for_Up_stim = 200. (ms)
	Dur_for_Down_stim = 200. (ms)
	Up_Stim_Periodicity = 3
	Down_Stim_Periodicity = 3
	CMD_delay = -20 (ms)
	CMD_dur = 380 (ms)
}

ASSIGNED {
	cao (mV)
	cai (pA)
	i_LP (pA)
	V_LASER (mV)
	weights[100]
	vec[100]
	stim_vec[2000]
	delay_vec[2000]
	duration_vec[2000]
	amplitude_vec[2000]
	cmd_vec[2000]
	up_transition_vec[2000]
	down_transition_vec[2000]
	i_up
	i_down
	Up_flag
	up_time_start (ms)
	down_time_start (ms)
        up_blank_flag
	down_blank_flag
        up_stimulation
	down_stimulation
	norm_factor
	dt2
}

INITIAL {
    FROM j=0 TO (N-1) {vec[j] = 0}
    FROM j=0 TO (N-1) {weights[j] = exp(-3.0*j/N)}
    norm_factor = 0
    FROM j=0 TO (N-1) {norm_factor = norm_factor + weights[j]}
    FROM j=0 TO (N-1) {weights[j] = weights[j]/norm_factor}
    cao = 0
    i_LP = 0
    V_LASER = 0
    up_blank_flag = 0
    down_blank_flag = 1
    dt2 = 1./(subsampling_freq)
    i_up = 0
    i_down = 0
    FROM j=0 TO (Nvec-1) {up_transition_vec[j] = 0}
    FROM j=0 TO (Nvec-1) {down_transition_vec[j] = 0}
}
    

BREAKPOINT {

      : PERFORMED UNDER SUBSAMPLING CONDITIONS !!!
      if (fmod(t, dt2) < dt) {
      
	: =====================================================================
	: We compute the Real-Time Low-Pass-Filtered membrane potential
	: ---------------------------------------------------------------------
	: update with current v (with threshold for spikes)
      	vec[0] = cai
      	: then shift all history
      	FROM j=0 TO (N-2) {vec[(N-1)-j] = vec[(N-2)-j]} 
      	i_LP = 0.0 : new Low pass filtered v
      	FROM j=0 TO (N-1) {i_LP = i_LP + vec[j]*weights[j]} : compute
  
	: =====================================================================
	: Tracking transitions and updating variable
	: ---------------------------------------------------------------------
	if ( (i_LP>upward_threshold) && (cao==0)) { : ==> We are in Up state (test is disabled when the loop has triggered a VC stim)
	  : ---------------------------------------------------------------------
	  if (Up_flag==0) { : We were in Down state -> transitions !
	  up_time_start = t : so we note the time of the transition
	  up_transition_vec[i_up] = t
	  i_up = i_up + 1
	  }
	  Up_flag = 1 : State update -> Up
	}
	if ( (i_LP<downward_threshold) && (cao==0)){ : ==> We are in the Down state
	  : ---------------------------------------------------------------------
	  if (Up_flag==1) { : We were in Down state -> transitions !
	  down_time_start = t : so we note the time of the transition
	  down_transition_vec[i_down] = t
	  i_down = i_down + 1
	  }
	  Up_flag = 0 : State update -> Down
	}
	: else no state update !

	: =====================================================================
	: Triggering and removing stimulation -> *Voltage-Clamp Command*
	: =====================================================================
	: if a new Down state did not appear, if the time conditions are matched and if we
	: were not stimulation, we start the stimulation
	: ---------------------------------------------------------------------
	if ((t>up_time_start+delay_vec[i_up]+CMD_delay) && (t<=up_time_start+delay_vec[i_up]+CMD_delay+CMD_dur) && (up_stimulation>=0)) {
	  : the externally constructed vector (cmd_vec) decides whether that should be a blank trial or a test trial !
	  cao = cmd_vec[i_up]
	} else if (up_stimulation>=0) {cao = 0} : this test should control the command only of the up state controls the feedback loop !
	: =====================================================================
	: if a new Up state did not appear, if the time conditions are matched and if we
	: were not stimulation, we start the stimulation
	: ---------------------------------------------------------------------
	if ((t>down_time_start+delay_vec[i_down]+CMD_delay) && (t<=down_time_start+delay_vec[i_down]+CMD_delay+CMD_dur) && (down_stimulation>=0)) {
	  : the externally constructed vector (cmd_vec) decides whether that should ba a blamk trial or a test trial !
	  cao = cmd_vec[i_down]
	} else if (down_stimulation>=0) {cao = 0}
	
	: =====================================================================
	: Triggering and removing stimulation -> *LASER*
	: =====================================================================
	: if a new Down state did not appear, if the time conditions are matched and if we
	: were not stimulation, we start the stimulation
	: ---------------------------------------------------------------------
	if ((t>up_time_start+delay_vec[i_up]) && (up_stimulation==0) && (t<=up_time_start+delay_vec[i_up]+duration_vec[i_up]) && (stim_vec[i_up]==1)) {
	  : the externally constructed vector decides whether that should ba a blamk trial or a test trial !
	  up_stimulation = 1
	  V_LASER = amplitude_vec[i_up]
	}
	: =====================================================================
	: if a new Up state did not appear, if the time conditions are matched and if we
	: were not stimulation, we start the stimulation
	: ---------------------------------------------------------------------
	if ((t>down_time_start+delay_vec[i_down]) && (down_stimulation==0) && (t<=down_time_start+delay_vec[i_down]+duration_vec[i_down]) && (stim_vec[i_down]==1)) {
	  : the externally constructed vector decides whether that should ba a blamk trial or a test trial !
	  down_stimulation = 1
	  V_LASER = amplitude_vec[i_down]
	}
	: =====================================================================
	: N.B. if we are stimulating, we do not want that the evoked dynamics
	: perturb the scheduled stimulation, except if the stimulation should end !
	: ---------------------------------------------------------------------
	if ((up_stimulation==1) && (t>up_time_start+delay_vec[i_up]+duration_vec[i_up])) {
	  V_LASER=0
	  up_stimulation = 0
        }
	if ((down_stimulation==1) && (t>down_time_start+delay_vec[i_down]+duration_vec[i_down])) {
	  V_LASER=0
	  down_stimulation = 0
        }
      }
}
