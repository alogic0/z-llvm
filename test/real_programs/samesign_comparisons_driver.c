#include <stdint.h>
#include <stdio.h>

typedef uint64_t (*compare_fn)(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
#define DECLARE(name) extern uint64_t name(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *)
DECLARE(samesign_byte_named);
DECLARE(samesign_byte_negative);
DECLARE(samesign_half_named);
DECLARE(samesign_i21_literal);
DECLARE(samesign_i37_literal);
DECLARE(samesign_signed_word);
DECLARE(samesign_dirty_byte);
DECLARE(samesign_signed_named);

int main(void) {
    const uint64_t values[] = {
        0, 1, 2, 3, 7, 8, 99, 100, 101, 127, 128, 249, 250, 255, 256, 1023,
        1024, 2047, 2048, (UINT64_C(1) << 20) - 1, UINT64_C(1) << 20,
        (UINT64_C(1) << 21) - 1, INT32_MAX, UINT64_C(1) << 31, UINT32_MAX,
        (UINT64_C(1) << 36) - 1, UINT64_C(1) << 36, (UINT64_C(1) << 37) - 1,
        INT64_MAX, UINT64_C(1) << 63, UINT64_C(0xdeadbeef00000100), UINT64_MAX
    };
    const compare_fn functions[] = {samesign_byte_named, samesign_byte_negative,
        samesign_half_named, samesign_i21_literal, samesign_i37_literal,
        samesign_signed_word, samesign_dirty_byte, samesign_signed_named};
    const unsigned widths[] = {8, 8, 16, 21, 37, 32, 8, 64};
    unsigned observations = 0;
    for (unsigned i = 0; i < 32; ++i) for (unsigned j = 0; j < 32; ++j) {
        uint64_t a = values[i], b = values[j], c = values[(i + j + 3) % 32];
        uint64_t d = values[(i + 5) % 32], e = values[(j + 7) % 32];
        for (unsigned f = 0; f < 8; ++f) {
            uint64_t sign = UINT64_C(1) << (widths[f] - 1), mask = sign | (sign - 1);
            uint64_t lhs = a & mask, rhs = b & mask, expected;
            if (f == 1) rhs = 249;
            else if (f == 3) rhs = 2048;
            else if (f == 4) rhs = 14;
            else if (f == 5) rhs = UINT64_C(1) << 31;
            else if (f == 6) rhs = 100;
            if ((lhs ^ rhs) & sign) expected = 2; // Guarded source never evaluates poison.
            else if (f == 2) expected = lhs >= rhs;
            else if (f == 5) expected = (lhs ^ sign) > (rhs ^ sign);
            else if (f == 7) expected = (lhs ^ sign) < (rhs ^ sign);
            else expected = lhs < rhs;
            uint64_t out[] = {UINT64_C(0x123456789abcdef0), 0, 0, UINT64_C(0xfedcba9876543210)};
            uint64_t actual = functions[f](a, b, c, d, e, &out[1]);
            if (actual != expected || out[1] != (a ^ b ^ c ^ d ^ e) || out[2] != a ||
                out[0] != UINT64_C(0x123456789abcdef0) || out[3] != UINT64_C(0xfedcba9876543210)) {
                fprintf(stderr, "samesign comparison mismatch function=%u i=%u j=%u actual=%llu expected=%llu\n",
                    f, i, j, (unsigned long long)actual, (unsigned long long)expected);
                return 1 + f;
            }
            ++observations;
        }
    }
    printf("samesign-comparisons observations=%u widths=immediates=defined-domain=aliases=guards=preserved\n", observations);
    return 0;
}
