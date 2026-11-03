#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

extern uint32_t numeric_order(uint32_t);
extern uint32_t numeric_blocks(uint32_t);
extern uint32_t numeric_implicit(uint32_t);
extern uint32_t numeric_loop(uint32_t);
extern uint32_t numeric_call(uint32_t);
extern uint32_t numeric_switch(uint32_t);

uint32_t numeric_external(uint32_t x) { return x ^ UINT32_C(0xa5a5a5a5); }

int main(void) {
    const uint32_t inputs[] = {
        0, 1, 2, 3, 7, 8, 31, 32,
        UINT32_C(0x7fffffff), UINT32_C(0x80000000), UINT32_C(0xfffffffe),
        UINT32_C(0xffffffff), UINT32_C(0x5a5a5a5a), UINT32_C(0xa5a5a5a5),
        UINT32_C(0x01234567), UINT32_C(0x89abcdef)
    };
    for (unsigned i = 0; i < sizeof(inputs) / sizeof(inputs[0]); ++i) {
        const uint32_t x = inputs[i];
        const uint32_t actual[] = {
            numeric_order(x), numeric_blocks(x), numeric_implicit(x),
            numeric_loop(x & 31), numeric_call(x), numeric_switch(x)
        };
        const uint32_t expected[] = {
            (x ^ 7) + 3, (x ^ 7) + 3, x + 1,
            x & 31, (x ^ UINT32_C(0xa5a5a5a5)) + 3, x == 0 ? 7 : 9
        };
        for (unsigned j = 0; j < sizeof(actual) / sizeof(actual[0]); ++j) {
            if (actual[j] != expected[j]) {
                fprintf(stderr, "numeric local mismatch input=%u function=%u\n", i, j);
                return 1;
            }
            printf("%u:%u:%08" PRIx32 "\n", i, j, actual[j]);
        }
    }
    return 0;
}
