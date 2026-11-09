#include <stdint.h>
#include <stdio.h>

typedef uint64_t (*freeze_fn)(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t freeze_alias3(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t freeze_alias8(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t freeze_alias10(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t freeze_alias16(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t freeze_alias31(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t freeze_load8(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t freeze_calls16(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t freeze_phi8(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t freeze_branch1(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t freeze_parameter8(uint8_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);

__attribute__((noinline)) uint64_t freeze_clobber(uint64_t input) {
    uint64_t result = input ^ UINT64_C(0xfeedface87654321);
    __asm__ volatile("" : "+a"(result) : : "rdi", "rsi", "rdx", "rcx", "r8", "r9", "r10", "r11", "memory", "cc");
    return result;
}

int main(void) {
    const uint64_t values[] = {
        0, 1, 2, 3, 7, 8, 255, 256, 1023, 1024, 65535, 65536,
        UINT32_MAX, UINT64_C(0x8000000000000000), UINT64_C(0xfedcba9876543210), UINT64_MAX
    };
    const freeze_fn functions[] = {
        freeze_alias3, freeze_alias8, freeze_alias10, freeze_alias16, freeze_alias31,
        freeze_load8, freeze_calls16, freeze_phi8, freeze_branch1
    };
    const unsigned widths[] = {3, 8, 10, 16, 31};
    unsigned observations = 0;
    for (unsigned i = 0; i < 16; ++i) for (unsigned j = 0; j < 16; ++j) {
        uint64_t a = values[i], b = values[j], c = values[(i + j + 3) % 16];
        uint64_t d = values[(i + 5) % 16], e = values[(j + 7) % 16];
        for (unsigned f = 0; f < 10; ++f) {
            uint64_t sum = a + b, live = a ^ b ^ c ^ d ^ e;
            uint64_t initial = c ^ UINT64_C(0xa5a5a5a5a5a5a5a5), expected;
            if (f < 5) expected = sum & ((UINT64_C(1) << widths[f]) - 1);
            else if (f == 5) expected = initial & 255;
            else if (f == 6) expected = (c & 65535) ^ a ^ b;
            else if (f == 7) expected = (a < b ? a : b) & 255;
            else if (f == 8) expected = (a & 1) ? a : b;
            else {
                expected = a & 255;
                sum = expected;
                live = expected ^ b ^ c ^ d ^ e;
            }
            uint64_t out[] = {UINT64_C(0x123456789abcdef0), initial, 0, UINT64_C(0xfedcba9876543210)};
            uint64_t actual = f == 9 ? freeze_parameter8((uint8_t)a, b, c, d, e, &out[1]) : functions[f](a, b, c, d, e, &out[1]);
            if (actual != expected || out[1] != sum || out[2] != live ||
                out[0] != UINT64_C(0x123456789abcdef0) || out[3] != UINT64_C(0xfedcba9876543210)) {
                fprintf(stderr, "narrow freeze mismatch function=%u i=%u j=%u actual=%llu expected=%llu\n", f, i, j,
                    (unsigned long long)actual, (unsigned long long)expected);
                return 1 + f;
            }
            ++observations;
        }
    }
    printf("narrow-freeze observations=%u bits=aliases=branches=phis=calls=guards=preserved\n", observations);
    return 0;
}
