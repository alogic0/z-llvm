#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef uint64_t (*product_fn)(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t checked_select24(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t checked_binary40(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t checked_rhs_high(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t checked_spill_high(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t checked_signed120(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t checked_alias56(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t checked_calls48(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t checked_phi12(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);

__attribute__((noinline)) uint64_t checked_multiply_clobber(uint64_t value) {
    uint64_t result = value ^ UINT64_C(0xfeedface87654321);
    __asm__ volatile("" : "+a"(result) : : "rdi", "rsi", "rdx", "rcx", "r8", "r9", "r10", "r11", "memory", "cc");
    return result;
}

int main(void) {
    const uint64_t values[] = {
        0, 1, 2, 9, 10, 11, UINT32_MAX, UINT64_C(0x100000000),
        UINT64_MAX / 24, UINT64_MAX / 24 + 1, UINT64_MAX / 40, UINT64_MAX / 40 + 1,
        INT64_MAX, UINT64_C(0x8000000000000000), UINT64_MAX - 1, UINT64_MAX
    };
    const product_fn functions[] = {
        checked_select24, checked_binary40, checked_rhs_high, checked_spill_high,
        checked_signed120, checked_alias56, checked_calls48, checked_phi12
    };
    unsigned observations = 0;
    for (unsigned i = 0; i < 16; ++i) for (unsigned j = 0; j < 16; ++j) {
        uint64_t a = values[i], b = values[j], c = values[(i + j + 3) % 16];
        uint64_t d = values[(i + 5) % 16], e = values[(j + 7) % 16];
        for (unsigned f = 0; f < 8; ++f) {
            uint64_t lhs = a, rhs = 0, live = a ^ b ^ c ^ d ^ e;
            switch (f) {
            case 0: lhs = (a | 16) < (b | 16) ? (a | 16) : (b | 16); rhs = 24; break;
            case 1: lhs = a + b; rhs = 40; break;
            case 2: rhs = UINT64_MAX; break;
            case 3: lhs = a < b ? a : b; rhs = UINT64_C(0x8000000000000000); break;
            case 4: rhs = (uint64_t)-120; break;
            case 5: lhs = c + 7; rhs = 56; live ^= lhs ^ (uint32_t)lhs; break;
            case 6: {
                uint64_t before = a ^ UINT64_C(0xfeedface87654321);
                lhs = before < b ? before : b;
                rhs = 48;
                live ^= before ^ (c ^ UINT64_C(0xfeedface87654321));
                break;
            }
            case 7: lhs = a < b ? a + 3 : b ^ 7; rhs = 12; break;
            }
            unsigned __int128 full = (unsigned __int128)lhs * rhs;
            uint64_t overflow = full > UINT64_MAX;
            if (f == 4) {
                int64_t signed_lhs;
                memcpy(&signed_lhs, &lhs, sizeof signed_lhs);
                __int128 signed_full = (__int128)signed_lhs * -120;
                overflow = signed_full < INT64_MIN || signed_full > INT64_MAX;
            }
            uint64_t out[] = {UINT64_C(0x123456789abcdef0), 0, 0, UINT64_C(0xfedcba9876543210)};
            uint64_t actual = functions[f](a, b, c, d, e, &out[1]);
            if (actual != overflow || out[1] != (uint64_t)full || out[2] != live ||
                out[0] != UINT64_C(0x123456789abcdef0) || out[3] != UINT64_C(0xfedcba9876543210)) {
                fprintf(stderr, "checked multiply mismatch function=%u i=%u j=%u\n", f, i, j);
                return 1 + f;
            }
            ++observations;
        }
    }
    printf("checked-multiply observations=%u literals=overflow=aliases=calls=phis=guards=preserved\n", observations);
    return 0;
}
