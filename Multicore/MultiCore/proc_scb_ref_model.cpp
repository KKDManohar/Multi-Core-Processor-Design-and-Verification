#include <stdint.h>

extern "C" int reference_model(uint8_t A, uint8_t B, uint8_t op_sel) {

    int result = 0;

    switch(op_sel) {
        case 0: result = 0;
        case 1: result = A + B; break;
        case 2: result = A & B; break;
        case 3: result = A - B; break;
        case 4: result = A * B; break;
        case 7: result = ((A << 8) | B) >> 1; break;
        case 8: result = ((A << 8) | B) << 1; break;
        case 9: result = (A * B) - A; break;
        case 10: result = (A * 4 * B) - A; break;
        case 11: result = (A * B) + A; break;
        case 12: result =  A * 3; break;
        case 13: result = A ^ B; break;
        case 14: result = A | B; break;
        case 15: result = A ^ (~B); break;
        default: result = -1; break;
    }

    return result;

}