#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern uint32_t contract_unbounded(uint64_t);
extern uint32_t contract_typed(uint64_t);
extern uint32_t contract_literal(uint64_t);
extern uint32_t contract_masked(uint64_t);
extern uint32_t contract_stride4(uint64_t);
extern uint32_t contract_array_element(uint64_t);
extern uint32_t contract_wide(uint64_t);
extern uint32_t contract_mixed(uint64_t);
extern uint32_t contract_shifted_wide(uint64_t);
extern const void *contract_escaped(uint64_t);

static uint32_t value(uint64_t index) {
    return (uint16_t)(UINT32_C(0x9e37) + index * 257);
}

static uint32_t wide_value(uint64_t index) {
    return value(index) | (value(index + 1) << 16);
}

int main(int argc, char **argv) {
    unsigned fault = argc == 2 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    if (argc > 2 || fault > 10) return 2;
    unsigned observations = 0;
    for (unsigned input = 0; input < 128; ++input) {
        uint64_t index = input & 63;
        uint64_t bounded_input = index | (input >= 64 ? UINT64_C(0xffffabcd00000000) : 0);
        uint32_t escaped;
        memcpy(&escaped, contract_escaped(bounded_input), sizeof escaped);
        uint32_t actual[] = {contract_unbounded(index), contract_typed(index),
            contract_literal(index), contract_masked(bounded_input),
            contract_stride4(bounded_input), contract_array_element(index),
            contract_wide(bounded_input), contract_mixed(bounded_input),
            contract_shifted_wide(bounded_input), escaped};
        const uint32_t expected[] = {value(index), value(index), value(17),
            value(index), value((index & 15) * 2), value(index),
            wide_value(index & 31), wide_value(index & 31) + value(index & 31),
            wide_value((index & 31) + 1), wide_value(index & 31)};
        if (fault) actual[fault - 1] ^= 1;
        for (unsigned which = 0; which < 10; ++which) {
            if (actual[which] != expected[which]) {
                fprintf(stderr, "table-contracts which=%u input=%u fault=%u\n",
                    which, input, fault);
                return 1;
            }
            ++observations;
        }
    }
    printf("table-contracts observations=%u fallback=typed=literal=bounded=strides=consumers=preserved\n",
        observations);
    return 0;
}
