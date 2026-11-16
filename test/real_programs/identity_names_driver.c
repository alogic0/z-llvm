#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

extern uint64_t identity_sum(uint64_t, uint64_t);
extern uint64_t identity_difference(uint64_t, uint64_t);
extern uint64_t identity_mix(uint64_t, uint64_t);
extern uint64_t identity_call(uint64_t, uint64_t);

uint64_t identity_sink(uint64_t left, uint64_t right) {
    return (left * UINT64_C(3)) ^ right;
}

int main(int argc, char **argv) {
    unsigned fault = argc == 2 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    if (argc > 2 || fault > 4) return 2;
    const uint64_t edges[] = {0, 1, UINT64_MAX, UINT64_C(0x8000000000000000),
        UINT64_C(0x7fffffffffffffff), 17, 255, 256};
    unsigned observations = 0;
    for (unsigned input = 0; input < 264; ++input) {
        uint64_t left = input < 8 ? edges[input] : UINT64_C(0x9e3779b97f4a7c15) * (input - 8);
        uint64_t right = (left ^ UINT64_C(0xabcd1234ffff7890)) + input;
        const uint64_t expected[] = {left + right, left - right,
            ((left ^ right) + left) - right, (left * UINT64_C(3)) ^ right};
        uint64_t actual[] = {identity_sum(left, right), identity_difference(left, right),
            identity_mix(left, right), identity_call(left, right)};
        if (fault != 0) actual[fault - 1] ^= 1;
        for (unsigned which = 0; which < 4; ++which) {
            if (actual[which] != expected[which]) {
                fprintf(stderr, "identity-names which=%u input=%u fault=%u\n", which, input, fault);
                return 1;
            }
            ++observations;
        }
    }
    printf("identity-names observations=%u long=quoted=distinct=relocations=preserved\n", observations);
    return 0;
}
