#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern uint8_t padded_i24(void *);
extern uint8_t padded_i24_negative(void *);
extern uint8_t padded_f80(void *);
extern uint8_t padded_f80_negative(void *);
extern uint8_t padded_i40(void *);
extern uint8_t padded_i40_negative(void *);
extern uint8_t padded_vector(void *);
extern uint8_t padded_vector_negative(void *);

int main(int argc, char **argv) {
    unsigned fault = argc == 2 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    if (argc > 2 || fault > 8) return 2;
    uint8_t (*const functions[])(void *) = {
        padded_i24, padded_i24_negative, padded_f80, padded_f80_negative,
        padded_i40, padded_i40_negative, padded_vector, padded_vector_negative
    };
    const int stride[] = {4, -4, 16, -16, 8, -8, 16, -16};
    const int nearby[] = {3, -3, 10, -10, 5, -5, 12, -12};
    unsigned observations = 0;
    for (int base = 0; base < 32; ++base) {
        for (unsigned which = 0; which < 8; ++which) {
            uint8_t actual[96], expected[96];
            memset(actual, 131, sizeof actual);
            memset(expected, 131, sizeof expected);
            expected[base + 32 + stride[which]] = 22;
            expected[base + 32 + nearby[which]] = 11;
            uint8_t result = functions[which](actual + base + 32);
            if (fault == which + 1) result ^= 1;
            if (result != 11 || memcmp(actual, expected, sizeof actual) != 0) {
                fprintf(stderr, "padded-gep-alias which=%u base=%d fault=%u\n",
                    which, base, fault);
                return 1;
            }
            ++observations;
        }
    }
    printf("padded-gep-alias observations=%u strides=accesses=stores=preserved\n",
        observations);
    return 0;
}
