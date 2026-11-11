#include <stdint.h>
typedef uint64_t (*truncation_fn)(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_53_to_52(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_55_to_52(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_56_to_52(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_63_to_52(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_64_to_52(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_52_to_1(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_52_to_2(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_52_to_5(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_52_to_6(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_52_to_7(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_52_to_8(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_52_to_16(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_52_to_31(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_52_to_32(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_52_to_33(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_truncation_52_to_51(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);
static const struct { truncation_fn run; unsigned bits; } cases[]={
 {integer_truncation_53_to_52,52},
 {integer_truncation_55_to_52,52},
 {integer_truncation_56_to_52,52},
 {integer_truncation_63_to_52,52},
 {integer_truncation_64_to_52,52},
 {integer_truncation_52_to_1,1},
 {integer_truncation_52_to_2,2},
 {integer_truncation_52_to_5,5},
 {integer_truncation_52_to_6,6},
 {integer_truncation_52_to_7,7},
 {integer_truncation_52_to_8,8},
 {integer_truncation_52_to_16,16},
 {integer_truncation_52_to_31,31},
 {integer_truncation_52_to_32,32},
 {integer_truncation_52_to_33,33},
 {integer_truncation_52_to_51,51},
};
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned observations, fault;

static int mismatch(unsigned which, unsigned input, unsigned seed, const char *stage) {
    fprintf(stderr, "integer truncation mismatch case=%u input=%u seed=%u stage=%s fault=%u observation=%u\n",
            which, input, seed, stage, fault, observations);
    return 1;
}

int main(int argc, char **argv) {
    if (argc == 2) fault = (unsigned)strtoul(argv[1], 0, 10);
    if (argc > 2 || fault > 3) return 2;
    const uint64_t values[] = {
        0, 1, 2, 3, 127, 255, UINT32_MAX, UINT64_C(1) << 32,
        (UINT64_C(1) << 51) - 1, UINT64_C(1) << 51,
        (UINT64_C(1) << 52) - 1, UINT64_C(1) << 52,
        (UINT64_C(1) << 53) - 1, UINT64_C(1) << 63,
        UINT64_C(0xdeadbeef12345678), UINT64_MAX
    };
    const uint64_t seeds[] = {0, 1, UINT64_C(0xa55a55aa12345678), UINT64_MAX};
    for (unsigned k = 0; k < sizeof(cases) / sizeof(cases[0]); ++k) {
        unsigned bits = cases[k].bits, bytes = (bits + 7) / 8;
        uint64_t mask = (UINT64_C(1) << bits) - 1;
        for (unsigned a = 0; a < 16; ++a) for (unsigned s = 0; s < 4; ++s) {
            uint8_t guarded[16];
            memset(guarded, 0xa7, sizeof(guarded));
            uint8_t *out = guarded + 1;
            uint64_t input = values[a], live = seeds[s];
            uint64_t e1 = input ^ (live << 1), e2 = ~input + live;
            uint64_t e3 = (input >> 13) ^ live, e4 = input + 17 * s;
            uint64_t value = input & mask;
            uint64_t expected = value ^ input ^ ((((live ^ e1) + e2) ^ e3) + e4);
            uint64_t actual = cases[k].run(input, live, out, e1, e2, e3, e4);
            if (fault == 1) actual ^= 1;
            if (fault == 2) out[0] ^= 1;
            if (fault == 3) out[bytes] ^= 1;
            if (actual != expected) return mismatch(k, a, s, "return-live");
            uint64_t stored = 0;
            for (unsigned i = 0; i < bytes; ++i) stored |= (uint64_t)out[i] << (8 * i);
            if ((stored & mask) != value) return mismatch(k, a, s, "typed-store");
            if (guarded[0] != 0xa7) return mismatch(k, a, s, "prefix-guard");
            for (unsigned i = 1 + bytes; i < sizeof(guarded); ++i)
                if (guarded[i] != 0xa7) return mismatch(k, a, s, "suffix-guard");
            ++observations;
        }
    }
    if (observations != 1024) return mismatch(0, 0, 0, "count");
    puts("integer-truncation observations=1024 widths=padding=live=stores=guards=preserved");
    return 0;
}
