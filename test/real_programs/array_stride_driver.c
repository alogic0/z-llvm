#include <stdint.h>
#include <stdio.h>

#define DECLARE(name) extern uint64_t name(void *, uint64_t, uint64_t, void **, uint64_t)
DECLARE(array_stride_eight);
DECLARE(array_stride_padding);
DECLARE(array_stride_nested);
DECLARE(array_stride_loaded);

typedef uint64_t (*Probe)(void *, uint64_t, uint64_t, void **, uint64_t);

int main(void) {
    uint64_t anchor = 0;
    const uint64_t bases[] = {
        0, 1, 4096, UINT64_MAX, UINT64_MAX - 7,
        UINT64_C(0x8000000000000000), UINT64_C(0x7fff00000000),
        (uintptr_t)&anchor
    };
    const uint64_t indexes[] = {
        0, 1, 2, 7, UINT64_MAX, UINT64_MAX - 1,
        UINT64_C(0x8000000000000000), UINT64_C(0x2000000000000001)
    };
    const Probe functions[] = {
        array_stride_eight, array_stride_padding,
        array_stride_nested, array_stride_loaded
    };
    const uint64_t strides[] = { 8, 4, 32, 8 };
    const uintptr_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned b = 0; b < 8; ++b) {
        for (unsigned i = 0; i < 8; ++i) {
            const uint64_t live = UINT64_C(0x123456789abcdef0) ^ indexes[i];
            const uint64_t salt = UINT64_C(0xfedcba9876543210) ^ bases[b];
            for (unsigned f = 0; f < 4; ++f) {
                void *output[] = { (void *)guard, NULL, (void *)guard };
                /* Integer arithmetic supplies the independent wrapping oracle;
                 * the synthetic pointers are only computed and never dereferenced. */
                const uint64_t address = bases[b] + indexes[i] * strides[f];
                const uint64_t expected = address ^ bases[b] ^ indexes[i] ^ live ^ salt;
                const uint64_t actual = functions[f]((void *)(uintptr_t)bases[b], indexes[i], live, &output[1], salt);
                if ((uintptr_t)output[1] != address || actual != expected ||
                    (uintptr_t)output[0] != guard || (uintptr_t)output[2] != guard) {
                    fprintf(stderr, "array stride mismatch function=%u base=%u index=%u\n", f, b, i);
                    return 1;
                }
                ++observations;
            }
        }
    }
    printf("array-stride observations=%u padding=nested=negative=wrap=live=guards=preserved\n", observations);
    return 0;
}
