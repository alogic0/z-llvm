/* Bitwise paired execution against LLVM 22 compiling the identical frozen IR.
 * Seeded finite triples include subnormal inputs and extreme exponent gaps.
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
extern double reference_fma(double, double, double);
extern double local_fma(double, double, double) __asm__("compiler_rt.fma.fma");
static uint64_t state = UINT64_C(0x5eed1234f00dcafe);
static uint64_t next(void) { state = state * UINT64_C(6364136223846793005) + UINT64_C(1442695040888963407); return state; }
static double value(uint64_t bits) { double d; memcpy(&d, &bits, 8); return d; }
static uint64_t bits(double value) { uint64_t result; memcpy(&result, &value, 8); return result; }
int main(void) {
    for (unsigned i = 0; i < 8192; ++i) {
        uint64_t x = next(), y = next(), z = next();
        if (((x >> 52) & 2047) == 2047) x ^= UINT64_C(1) << 52;
        if (((y >> 52) & 2047) == 2047) y ^= UINT64_C(1) << 52;
        if (((z >> 52) & 2047) == 2047) z ^= UINT64_C(1) << 52;
        if (i % 8 == 0) x &= UINT64_C(0x800fffffffffffff);
        if (i % 8 == 1) y &= UINT64_C(0x800fffffffffffff);
        double actual = local_fma(value(x), value(y), value(z));
        double expected = reference_fma(value(x), value(y), value(z));
        if (bits(actual) != bits(expected)) {
            fprintf(stderr, "fma mismatch case=%u x=%016llx y=%016llx z=%016llx expected=%016llx actual=%016llx\n", i, (unsigned long long)x, (unsigned long long)y, (unsigned long long)z, (unsigned long long)bits(expected), (unsigned long long)bits(actual));
            return 1;
        }
    }
    puts("summary fma-differential cases=8192 matched=8192 reference=llvm22-frozen-ir local_fail=0");
    return 0;
}
