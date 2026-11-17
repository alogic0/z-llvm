#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

extern uint64_t layout_i80_array(uint64_t);
extern uint64_t layout_i80_struct(uint64_t);
extern uint64_t layout_i24_array(uint64_t);
extern uint64_t layout_i24_struct(uint64_t);
extern uint64_t layout_i9_array(uint64_t);

int main(int argc, char **argv) {
    unsigned fault = argc == 2 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    if (argc > 2 || fault > 10) return 2;
    uint64_t (*const functions[])(uint64_t) = {
        layout_i80_array, layout_i80_struct, layout_i24_array,
        layout_i24_struct, layout_i9_array
    };
    const uint64_t sizes[] = {16, 24, 8, 16, 4};
    const uint64_t alignments[] = {8, 8, 8, 8, 4};
    unsigned observations = 0;
    for (uint64_t input = 0; input < 64; ++input) {
        const uint64_t seed = input * UINT64_C(0x9e3779b97f4a7c15);
        for (unsigned which = 0; which < 5; ++which) {
            const uint64_t expected = seed ^ ((sizes[which] << 16) | alignments[which]);
            uint64_t actual = functions[which](seed);
            if (fault == 2 * which + 1) actual ^= UINT64_C(1) << 16;
            if (fault == 2 * which + 2) actual ^= 1;
            if (actual != expected) {
                fprintf(stderr, "layout-integer which=%u input=%llu fault=%u\n",
                    which, (unsigned long long)input, fault);
                return 1;
            }
            ++observations;
        }
    }
    printf("layout-integer observations=%u strides=alignments=preserved\n", observations);
    return 0;
}
