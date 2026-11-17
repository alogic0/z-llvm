#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

extern uint32_t contract_layout(uint64_t);

int main(int argc, char **argv) {
    unsigned fault = argc == 2 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    if (argc > 2 || fault > 1) return 2;
    for (unsigned input = 0; input < 128; ++input) {
        uint64_t index = UINT64_C(0x9e3779b97f4a7c15) * input;
        /* [2 x i8] allocates 8 bytes under i8:32: four i16 elements. */
        uint32_t expected = (uint16_t)(UINT32_C(0x9e37) + (index & 15) * 4 * 257);
        uint32_t actual = contract_layout(index) ^ fault;
        if (actual != expected) {
            fprintf(stderr, "table-layout input=%u expected=%u actual=%u\n",
                input, expected, actual);
            return 1;
        }
    }
    puts("table-layout observations=128 allocation-stride=8");
    return 0;
}
