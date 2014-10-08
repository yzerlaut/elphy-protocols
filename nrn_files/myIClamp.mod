COMMENT
ADAPTED from IClamp.mod by yann zerlaut : zerlaut@unic.cnrs-gif.fr UNIC lab 2013
for the RTneuron-Simulation mode in Elphy
(making it more simple (no dur neither amp) just a Ipico current
value that will be set up by Elphy
---------------------------------------------------------------------------
Since this is an electrode current, positive values of i depolarize the cell
and in the presence of the extracellular mechanism there will be a change
in vext since i is not a transmembrane current but a current injected
directly to the inside of the cell.
ENDCOMMENT

NEURON {
	POINT_PROCESS myIClamp
	RANGE i, Ipico
	ELECTRODE_CURRENT i
}
UNITS {
	(nA) = (nanoamp)
}

ASSIGNED { 
    i (nA) 
    Ipico
}

INITIAL {
    i = 0
    Ipico = 0
}

BREAKPOINT {
    UNITSOFF
    i = 0.001*Ipico
    UNITSON
}
