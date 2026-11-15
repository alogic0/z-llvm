#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern void negate80(const void *, void *);
extern void negate128(const void *, void *);
extern void negate_vector80(const void *, void *);
extern void negate_vector128(const void *, void *);

static unsigned observations;

static void check(const uint8_t *input, const uint8_t *output, unsigned size) {
    for (unsigned byte = 0; byte != size; ++byte)
        assert(output[byte] == (input[byte] ^ (byte == size - 1 ? 0x80 : 0)));
    ++observations;
}

int main(void) {
    const uint64_t extended[][2] = {
        {0, 0}, {0, 0x8000}, {1, 0}, {1, 0x8000},
        {UINT64_MAX, 0}, {UINT64_MAX, 0x8000},
        {0x8000000000000000, 1}, {0x8000000000000000, 0x8001},
        {0x8000000000000000, 0x3fff}, {0x8000000000000000, 0xbfff},
        {UINT64_MAX, 0x7ffe}, {UINT64_MAX, 0xfffe},
        {0x8000000000000000, 0x7fff}, {0x8000000000000000, 0xffff},
        {0xc000000000000123, 0x7fff}, {0x8000000000000001, 0xffff},
    };
    const uint64_t quad[][2] = {
        {0, 0}, {0, 0x8000000000000000}, {1, 0}, {1, 0x8000000000000000},
        {UINT64_MAX, 0x0000ffffffffffff}, {UINT64_MAX, 0x8000ffffffffffff},
        {0, 0x0001000000000000}, {0, 0x8001000000000000},
        {0, 0x3fff000000000000}, {0, 0xbfff000000000000},
        {UINT64_MAX, 0x7ffeffffffffffff}, {UINT64_MAX, 0xfffeffffffffffff},
        {0, 0x7fff000000000000}, {0, 0xffff000000000000},
        {0x123, 0x7fff800000000000}, {1, 0xffff000000000000},
    };
    for (unsigned wide = 0; wide != 2; ++wide) {
        const unsigned size = wide ? 16 : 10;
        const uint64_t (*values)[2] = wide ? quad : extended;
        void (*scalar)(const void *, void *) = wide ? negate128 : negate80;
        void (*vector)(const void *, void *) = wide ? negate_vector128 : negate_vector80;
        for (unsigned i = 0; i != 16; ++i) {
            uint8_t guarded[50];
            memset(guarded, 0xa7, sizeof guarded);
            scalar(values[i], guarded + 1);
            check((const uint8_t *)values[i], guarded + 1, size);
            assert(guarded[0] == 0xa7);
            for (unsigned byte = size + 1; byte != sizeof guarded; ++byte)
                assert(guarded[byte] == 0xa7);
            for (unsigned j = 0; j != 16; ++j) {
                uint8_t input[32];
                memcpy(input, values[i], 16);
                memcpy(input + 16, values[j], 16);
                memset(guarded, 0xa7, sizeof guarded);
                vector(input, guarded + 1);
                check(input, guarded + 1, size);
                check(input + 16, guarded + 17, size);
                assert(guarded[0] == 0xa7);
                for (unsigned byte = size + 1; byte != 17; ++byte)
                    assert(guarded[byte] == 0xa7);
                for (unsigned byte = size + 17; byte != sizeof guarded; ++byte)
                    assert(guarded[byte] == 0xa7);
            }
        }
    }
    assert(observations == 1056);
    puts("ok extended fneg: 4 functions, 1056 exact payload observations");
    return 0;
}
