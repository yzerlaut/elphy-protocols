#include <stdio.h>
#include "hocdec.h"
/* change name when structures in neuron.exe change*/
/* and also change the mos2nrn1.sh script */
int nocmodl5_5;
extern int nrnmpi_myid;
extern int nrn_nobanner_;
modl_reg(){
	nrn_mswindll_stdio(stdin, stdout, stderr);
    if (!nrn_nobanner_) if (nrnmpi_myid < 1) {
	fprintf(stderr, "Additional mechanisms from files\n");

fprintf(stderr," Exp2Syn_eiNtwk.mod");
fprintf(stderr," hh2.mod");
fprintf(stderr," myIClamp.mod");
fprintf(stderr," myVClamp.mod");
fprintf(stderr, "\n");
    }
_Exp2Syn_eiNtwk_reg();
_hh2_reg();
_myIClamp_reg();
_myVClamp_reg();
}
