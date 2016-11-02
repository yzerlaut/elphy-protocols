COMMENT
taken from the neuron forum, version of Hines/Ted
http://www.neuron.yale.edu/phpbb/viewtopic.php?f=16&t=2055
ENDCOMMENT

NEURON {
  POINT_PROCESS IClamp_WhiteNoise
  RANGE i,delay,dur,mean,std
  ELECTRODE_CURRENT i
}

UNITS {
  (nA) = (nanoamp)
}

PARAMETER {
  delay=50    (ms)
  dur=200   (ms)
  mean = 0.9 (nA)
  std=0.2   (nA)
}

ASSIGNED {
  ival (nA)
  i (nA)
  noise (nA)
  on (1)
}

INITIAL {
  i = 0
  on = 0
  net_send(delay, 1)
}

PROCEDURE seed(x) {
  set_seed(x)
}

BEFORE BREAKPOINT {
  if  (on) {
    noise = normrand(0,std*1(/nA))*1(nA)
    ival = mean + noise
  } else {
    ival = 0
  }
}

BREAKPOINT {
  i = ival
}

NET_RECEIVE (w) {
  if (flag == 1) {
    if (on == 0) {
      : turn it on
      on = 1
      : prepare to turn it off
      net_send(dur, 1)
    } else {
      : turn it off
      on = 0
    }
  }
}