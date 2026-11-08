#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern uint32_t same_direct(uint64_t, uint64_t);
extern uint32_t same_swapped(uint64_t, uint64_t);
extern uint64_t same_phi(uint64_t, uint64_t, uint32_t);
extern uint64_t same_call(uint64_t, uint64_t);
extern uint32_t same_load(const void *, void *);
extern uint64_t same_pressure(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);

static uint64_t oracle_call(uint64_t value) {
    return (value * UINT64_C(0x9e3779b97f4a7c15)) ^ UINT64_C(0x123456789abcdef0);
}

__attribute__((noinline)) uint64_t comparison_clobber(uint64_t value) {
    uint64_t result = oracle_call(value);
    __asm__ volatile(
        "xor %%eax, %%eax\n\t xor %%ecx, %%ecx\n\t xor %%edx, %%edx\n\t"
        "xor %%esi, %%esi\n\t xor %%edi, %%edi\n\t xor %%r8d, %%r8d\n\t"
        "xor %%r9d, %%r9d\n\t xor %%r10d, %%r10d\n\t xor %%r11d, %%r11d\n\t"
        "pxor %%xmm0, %%xmm0\n\t pxor %%xmm1, %%xmm1\n\t"
        "pxor %%xmm2, %%xmm2\n\t pxor %%xmm3, %%xmm3\n\t"
        "pxor %%xmm4, %%xmm4\n\t pxor %%xmm5, %%xmm5\n\t"
        "pxor %%xmm6, %%xmm6\n\t pxor %%xmm7, %%xmm7\n\t"
        "pxor %%xmm8, %%xmm8\n\t pxor %%xmm9, %%xmm9\n\t"
        "pxor %%xmm10, %%xmm10\n\t pxor %%xmm11, %%xmm11\n\t"
        "pxor %%xmm12, %%xmm12\n\t pxor %%xmm13, %%xmm13\n\t"
        "pxor %%xmm14, %%xmm14\n\t pxor %%xmm15, %%xmm15"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11",
                     "xmm0", "xmm1", "xmm2", "xmm3", "xmm4", "xmm5", "xmm6", "xmm7",
                     "xmm8", "xmm9", "xmm10", "xmm11", "xmm12", "xmm13", "xmm14", "xmm15", "cc", "memory");
    return result;
}

int main(void) {
    const uint64_t boundary[] = {0, 1, 2, UINT64_C(0x7fffffff), UINT64_C(0x80000000),
        UINT64_C(0xffffffff), UINT64_C(0x100000000), UINT64_C(0x7ffffffffffffffe), UINT64_C(0x7fffffffffffffff)};
    unsigned observations = 0;
    uint64_t state = UINT64_C(0xa7189d36120fbe4c);
    for (unsigned i = 0; i < 512; ++i) {
        state ^= state << 13;
        state ^= state >> 7;
        state ^= state << 17;
        uint64_t sign = (uint64_t)(i & 1) << 63;
        uint64_t a = (i < 162 ? boundary[(i / 2) % 9] : state & UINT64_C(0x7fffffffffffffff)) | sign;
        uint64_t b = (i < 162 ? boundary[(i / 18) % 9] : (state >> 1) ^ UINT64_C(0x13579bdf2468ace0)) | sign;
        if (same_direct(a, b) != (a < b) || same_swapped(a, b) != (b < a)) return 1;
        observations += 2;
        for (unsigned choose = 0; choose < 2; ++choose) {
            uint64_t x = choose ? a : b, y = choose ? b : a;
            if (same_phi(a, b, choose) != ((x * 17) ^ y) + (uint64_t)(x < y)) return 2;
            ++observations;
        }
        uint64_t expected = (oracle_call(a) ^ b) + (uint64_t)(a < b) + 7 * (uint64_t)(b < a);
        if (same_call(a, b) != expected) return 3;
        ++observations;
        unsigned char input[18], output[10];
        memset(input, 0x5a, sizeof(input));
        memset(output, 0xa5, sizeof(output));
        memcpy(input + 1, &a, 8);
        memcpy(input + 9, &b, 8);
        if (same_load(input + 1, output + 1) != (a < b)) return 4;
        uint64_t stored;
        memcpy(&stored, output + 1, 8);
        if (stored != (a ^ b) || output[0] != 0xa5 || output[9] != 0xa5 || input[0] != 0x5a || input[17] != 0x5a) return 5;
        ++observations;
        uint64_t c = ~a, d = state, e = b + UINT64_C(0xabcdef0011223344), f = ~state;
        uint64_t x = a ^ c, y = b + d, z = e ^ f;
        expected = (((x + y) + (oracle_call(z) ^ z)) ^ ((c + d) ^ (e ^ f))) + (uint64_t)(a < b);
        if (same_pressure(a, b, c, d, e, f) != expected) return 6;
        ++observations;
    }
    printf("comparison-facts observations=%u same-sign=boundaries=aliases=calls=phis=spills=preserved\n", observations);
    return 0;
}
