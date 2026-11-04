#include <assert.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

extern uint32_t attribute_read_constant(uint32_t);
extern uint32_t attribute_store_load(uint32_t);
extern uint32_t attribute_call_chain(uint32_t);
extern uint32_t attribute_alias_load(uint32_t);
extern uint32_t attribute_merged_load(void);
extern uint32_t attribute_alias;

int main(void) {
    static const uint32_t inputs[] = {
        0, 1, 7, 17, 23, 31, 1024, 1000000,
        UINT32_C(0x7ffffffe), UINT32_C(0x7fffffff), UINT32_C(0x80000000),
        UINT32_C(0x80000001), UINT32_C(0xffffffdf), UINT32_C(0xfffffffb),
        UINT32_MAX - 1, UINT32_MAX
    };
    for (unsigned i = 0; i < sizeof(inputs) / sizeof(inputs[0]); ++i) {
        const uint32_t x = inputs[i];
        const uint32_t constant = attribute_read_constant(x);
        const uint32_t stored = attribute_store_load(x);
        const uint32_t called = attribute_call_chain(x);
        const uint32_t aliased = attribute_alias_load(x);
        const uint32_t merged = attribute_merged_load();
        assert(constant == x + UINT32_C(23) && stored == x);
        assert(called == x + UINT32_C(5) && aliased == x);
        assert(attribute_alias == x && merged == 14);
        printf("%u %" PRIu32 " %" PRIu32 " %" PRIu32 " %" PRIu32 " %" PRIu32 "\n",
               i, constant, stored, called, aliased, merged);
    }
    return 0;
}
