#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern float phi_fp_literal32(float, uint32_t);
extern double phi_fp_literal64(double, uint32_t);
int main(int argc, char **argv) {
    const unsigned fault = argc > 1 ? (unsigned)strtoul(argv[1], 0, 10) : 0;
    const double inputs[] = {-100., -1., -.25, -0., 0., .25, .3, .34657356, .4, 1., 100.};
    unsigned observations = 0;
    for (unsigned i = 0; i < sizeof(inputs) / sizeof(inputs[0]); ++i) {
        for (uint32_t which = 0; which < 3; ++which) {
            const float x = (float)inputs[i];
            const float expected32 = (x + x) + (which == 0 ? 0.f : 1.f);
            const double expected64 = (inputs[i] + inputs[i]) + (which == 0 ? 0. : 1.);
            float actual32 = phi_fp_literal32(x, which);
            double actual64 = phi_fp_literal64(inputs[i], which);
            uint32_t bits32;
            uint64_t bits64;
            if (fault == 1) { memcpy(&bits32, &actual32, 4); bits32 ^= 1; memcpy(&actual32, &bits32, 4); }
            if (fault == 2) { memcpy(&bits64, &actual64, 8); bits64 ^= 1; memcpy(&actual64, &bits64, 8); }
            if (fault == 3) actual32 += 3.f;
            if (memcmp(&actual32, &expected32, 4) != 0 || memcmp(&actual64, &expected64, 8) != 0) {
                fprintf(stderr, "phi-fp-literals mismatch case=%u branch=%u fault=%u\n", i, which, fault);
                return 1;
            }
            observations += 2;
        }
    }
    printf("phi-fp-literals observations=%u snapshots=preserved\n", observations);
    return 0;
}
