#include <stdint.h>
#include <stdio.h>

extern uint64_t scalar_stack_roundtrip(uint64_t, uint64_t, void *);
extern void scalar_stack_constants(void *);
extern uint64_t scalar_stack_null(void *);

int main(void) {
    const uint64_t values[] = {0, UINT64_C(2147483648), UINT32_MAX,
        UINT64_C(4294967296), INT64_MAX, UINT64_C(1) << 63, UINT64_MAX,
        UINT64_C(0xdeadbeef01234567)};
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned v = 0; v < 8; ++v) {
        for (unsigned l = 0; l < 8; ++l) {
            struct { uint64_t before, value, after; } output = {guard, 17, guard};
            if (scalar_stack_roundtrip(values[v], values[l], &output.value) != (values[v] ^ values[l]) ||
                output.value != values[v] || output.before != guard || output.after != guard)
                return 1;
            ++observations;
        }
    }
    struct { uint64_t before, values[16], after; } output = {guard, {0}, guard};
    scalar_stack_constants(output.values);
    for (unsigned i = 0; i < 16; ++i) {
        if (output.values[i] != values[i % 8]) {
            fprintf(stderr, "scalar stack constant mismatch field=%u actual=%016llx expected=%016llx\n",
                i, (unsigned long long)output.values[i], (unsigned long long)values[i % 8]);
            return 2;
        }
        ++observations;
    }
    if (output.before != guard || output.after != guard) return 3;
    void *pointer = &output;
    if (scalar_stack_null(&pointer) != 0 || pointer != 0) return 4;
    ++observations;
    printf("scalar-stack-memory observations=%u full-width=preserved null=preserved guards=preserved\n", observations);
    return 0;
}
