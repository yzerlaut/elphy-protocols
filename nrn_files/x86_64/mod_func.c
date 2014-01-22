#include <stdio.h>
#include "hocdec.h"
extern int nrnmpi_myid;
extern int nrn_nobanner_;
modl_reg(){
  if (!nrn_nobanner_) if (nrnmpi_myid < 1) {
    fprintf(stderr, "Additional mechanisms from files\n");

    fprintf(stderr," Exp2Syn_eiNtwk.mod");
    fprintf(stderr," hh2.mod");
    fprintf(stderr," instantaneous_freq.mod");
    fprintf(stderr," myIClamp.mod");
    fprintf(stderr," myVClamp.mod");
    fprintf(stderr," netstim2.mod");
    fprintf(stderr, "\n");
  }
  _Exp2Syn_eiNtwk_reg();
  _hh2_reg();
  _instantaneous_freq_reg();
  _myIClamp_reg();
  _myVClamp_reg();
  _netstim2_reg();
}
