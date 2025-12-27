#include <stdint.h>

static int last_grant = -1;

extern "C" uint8_t arbiter_ref(uint8_t req_arb){

    if(req_arb == 0){
        return 0;
    }

    for(int i = 0; i <= 3; i++){
        int idx = (last_grant + i) % 3;
        if(req_arb & (1 << idx)) {
            last_grant = idx;
            return (i << idx);
        }
    }

    return 0;

}

