#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

extern uint32_t private_read_a(uint64_t);
extern uint32_t private_read_b(uint64_t);
extern uint32_t internal_read_a(uint64_t);
extern uint32_t internal_read_b(uint64_t);

int main(int argc, char **argv) {
    unsigned fault = argc == 2 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    if (argc > 2 || fault > 4) return 2;
    const unsigned seeds[] = {0x1111, 0x2222, 0x3333, 0x4444};
    unsigned observations = 0;
    for (unsigned input = 0; input < 128; ++input) {
        uint64_t index = UINT64_C(0x9e3779b97f4a7c15) * input;
        uint32_t actual[] = {private_read_a(index), private_read_b(index),
            internal_read_a(index), internal_read_b(index)};
        if (fault) actual[fault - 1] ^= 1;
        for (unsigned which = 0; which < 4; ++which) {
            uint32_t expected = (uint16_t)(seeds[which] + (index & 63) * 257);
            if (actual[which] != expected) {
                fprintf(stderr, "table-private-link which=%u input=%u fault=%u\n",
                    which, input, fault);
                return 1;
            }
            ++observations;
        }
    }
    printf("table-private-link observations=%u private=internal=isolated\n", observations);
    return 0;
}
