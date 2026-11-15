#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef uint64_t (*mul_fn)(const void *, const void *, uint64_t);
typedef uint64_t (*sub_fn)(void *, uint64_t, uint64_t, uint64_t, uint64_t);
extern uint64_t scalar_mul32_loaded(const void *, const void *, uint64_t);
extern uint64_t scalar_mul32_zext(const void *, const void *, uint64_t);
extern uint64_t scalar_mul32_square(const void *, const void *, uint64_t);
extern uint64_t scalar_sub64_large(void *, uint64_t, uint64_t, uint64_t, uint64_t);
extern uint64_t scalar_sub64_exponent(void *, uint64_t, uint64_t, uint64_t, uint64_t);
extern uint64_t scalar_sub64_negative_min32(void *, uint64_t, uint64_t, uint64_t, uint64_t);
extern uint64_t scalar_sub64_signbit(void *, uint64_t, uint64_t, uint64_t, uint64_t);
extern uint64_t scalar_sub32_signbit(void *, uint64_t, uint64_t, uint64_t, uint64_t);

__attribute__((noinline)) uint64_t preopt_scalar_touch(const uint64_t *address) {
    const uint64_t value = *address;
    __asm__ volatile("movabs $0x1122334455667788,%%rax\n\t"
                     "movabs $0x2233445566778899,%%rcx\n\t"
                     "movabs $0x33445566778899aa,%%rdx\n\t"
                     "movabs $0x445566778899aabb,%%rdi\n\t"
                     "movabs $0x5566778899aabbcc,%%rsi\n\t"
                     "movabs $0x66778899aabbccdd,%%r8\n\t"
                     "movabs $0x778899aabbccddee,%%r9\n\t"
                     "movabs $0x8899aabbccddeeff,%%r10\n\t"
                     "movabs $0x99aabbccddeeff00,%%r11\n\t"
                     "pxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1"
                     ::: "rax", "rcx", "rdx", "rdi", "rsi", "r8", "r9", "r10", "r11",
                         "xmm0", "xmm1", "cc", "memory");
    return value;
}

int main(int argc, char **argv) {
    unsigned fault = argc == 2 ? (unsigned)strtoul(argv[1], 0, 10) : 0;
    if (argc > 2 || fault > 3) return 2;
    const mul_fn products[] = {scalar_mul32_loaded, scalar_mul32_zext, scalar_mul32_square};
    const sub_fn differences[] = {scalar_sub64_large, scalar_sub64_exponent,
        scalar_sub64_negative_min32, scalar_sub64_signbit, scalar_sub32_signbit};
    const uint64_t literals[] = {UINT64_C(2147483648), UINT64_C(4503599627370496),
        UINT64_C(0xffffffff80000000), UINT64_C(0x8000000000000000)};
    const uint64_t values[] = {0, 1, 2, 0x7fff, 0x8000, 0xffff, 0x7fffffff,
        0x80000000, 0xffffffff, UINT64_C(0x100000000), UINT64_C(0x7fffffffffffffff),
        UINT64_C(0x8000000000000000), UINT64_MAX, UINT64_C(0xfedcba9876543210),
        UINT64_C(0x0123456789abcdef), UINT64_C(0xaaaaaaaa55555555)};
    unsigned observations = 0;
    for (unsigned i = 0; i != 16; ++i) for (unsigned j = 0; j != 16; ++j) {
        const uint64_t a = values[i], b = values[j];
        const uint64_t c = values[(i + 5) % 16], d = values[(j + 9) % 16];
        const uint64_t keep = c ^ d;
        for (unsigned which = 0; which != 8; ++which) {
            uint8_t left[24], right[24], left_before[24], right_before[24];
            memset(left, 0xa7, sizeof left); memset(right, 0x5a, sizeof right);
            memcpy(left + 3, &a, 8); memcpy(right + 5, &b, 8);
            memcpy(left_before, left, sizeof left); memcpy(right_before, right, sizeof right);
            uint64_t actual, expected;
            if (which < 3) {
                const uint64_t x = which == 1 ? (a & 0xffff) : (uint32_t)a;
                const uint64_t y = which == 1 ? (b & 0xffff) : (uint32_t)b;
                actual = products[which](left + 3, right + 5, keep);
                expected = (uint32_t)(x * (which == 2 ? x : y)) ^ x ^ keep;
                if (which != 2) expected ^= y;
            } else {
                const unsigned sub = which - 3;
                actual = differences[sub](0, a, b, c, d);
                expected = sub == 4 ? (uint32_t)((uint32_t)a - UINT32_C(0x80000000)) : a - literals[sub];
                expected ^= a ^ b ^ c ^ d;
            }
            if (fault == 1) actual ^= 1;
            if (fault == 2) left[3] ^= 1;
            if (fault == 3) right[23] ^= 1;
            if (actual != expected || memcmp(left, left_before, sizeof left) ||
                memcmp(right, right_before, sizeof right)) {
                fprintf(stderr, "preopt-scalar-ops case=%u i=%u j=%u fault=%u observation=%u\n",
                        which, i, j, fault, observations);
                return 1;
            }
            ++observations;
        }
    }
    printf("preopt-scalar-ops observations=%u independent-c-wrapping-goldens=live-operands=large-immediates=call-clobbers=guards=preserved\n", observations);
    return 0;
}
