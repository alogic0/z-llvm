#include <assert.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

extern uint32_t metadata_read_constant(uint32_t);
extern uint32_t metadata_store_gep_load(uint32_t);
extern uint32_t metadata_table_call(uint32_t);
extern uint32_t metadata_alias_load(uint32_t);
extern uint32_t metadata_constant_refs(void);
extern uint32_t metadata_alias;

int main(void) {
    static const uint32_t inputs[] = {
        0, 1, 7, 17, 23, 31, 1024, 1000000,
        UINT32_C(0x7ffffffe), UINT32_C(0x7fffffff), UINT32_C(0x80000000),
        UINT32_C(0x80000001), UINT32_C(0xffffffdf), UINT32_C(0xfffffffb),
        UINT32_MAX - 1, UINT32_MAX
    };
    for (unsigned i = 0; i < sizeof(inputs) / sizeof(inputs[0]); ++i) {
        const uint32_t x = inputs[i];
        const uint32_t constant = metadata_read_constant(x);
        const uint32_t stored = metadata_store_gep_load(x);
        const uint32_t called = metadata_table_call(x);
        const uint32_t aliased = metadata_alias_load(x);
        const uint32_t merged = metadata_constant_refs();
        assert(constant == x + UINT32_C(23) && stored == x);
        assert(called == x + UINT32_C(5) && aliased == x);
        assert(metadata_alias == x && merged == 14);
        printf("%u %" PRIu32 " %" PRIu32 " %" PRIu32 " %" PRIu32 " %" PRIu32 "\n",
               i, constant, stored, called, aliased, merged);
    }
    return 0;
}
