#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern unsigned char qs_data[80];
extern uint64_t quoted_four(uint64_t);
extern uint64_t quoted_eight(uint64_t);
extern uint64_t quoted_initializer(uint64_t);
extern uint64_t quoted_literal(void);
extern uint64_t quoted_call(uint64_t);
extern uint64_t quoted_mutate(uint64_t, uint64_t);
extern uint64_t quoted_phi(uint64_t, _Bool);
static unsigned bad_address;

__attribute__((noinline)) uint64_t qs_check(uint64_t first, uint64_t last, uint64_t negative, uint64_t seed) {
    if (first != (uintptr_t)(qs_data + 17) || last != (uintptr_t)(qs_data + 31) ||
        negative + 8 != (uintptr_t)qs_data) { bad_address = 1; return 0; }
    uint64_t value = (seed + qs_data[17]) ^ qs_data[31];
    __asm__ volatile ("xor %%eax, %%eax; xor %%ecx, %%ecx; xor %%edx, %%edx;"
                      "xor %%edi, %%edi; xor %%esi, %%esi; xor %%r8d, %%r8d;"
                      "xor %%r9d, %%r9d; xor %%r10d, %%r10d; xor %%r11d, %%r11d"
                      ::: "rax", "rcx", "rdx", "rdi", "rsi", "r8", "r9", "r10", "r11", "cc", "memory");
    return value;
}

int main(void) {
    const uint64_t four[] = {17, UINT64_C(0x8000000000000009), UINT64_MAX, 71};
    const uint64_t eight[] = {101, 3, UINT64_MAX-6, UINT64_C(0x100000001), 109, 11, UINT64_MAX-12, INT64_MAX};
    unsigned observations = 0;
    for (unsigned i = 0; i < 128; ++i) {
        unsigned char expected[80];
        for (unsigned j = 0; j < 80; ++j) expected[j] = (unsigned char)(i*37 + j*19);
        memcpy(qs_data, expected, sizeof(expected));
        uint64_t seed = UINT64_C(0xfedcba9876543210) + i*17, old;
        memcpy(&old, expected+8+(i%8)*8, sizeof(old));
        if (quoted_four(i%4) != four[i%4] || quoted_eight(i%8) != eight[i%8] ||
            quoted_initializer(i%8) != old || quoted_literal() != UINT64_C(0x123456789abcdef0)) return 1;
        observations += 4;
        if (quoted_phi(i%4, 1) != four[i%4] || quoted_phi(i%4, 0) != eight[i%4]) return 2;
        observations += 2;
        if (quoted_call(seed) != (((seed + expected[17]) ^ expected[31]) ^ seed) || bad_address) return 3;
        ++observations;
        if (quoted_mutate(i%8, seed) != old) return 4;
        memcpy(expected+8+(i%8)*8, &seed, sizeof(seed));
        if (memcmp(qs_data, expected, sizeof(expected))) return 5;
        ++observations;
    }
    printf("quoted-symbols observations=%u tables=escapes=aliases=initializers=offsets=phis=guards=preserved\n", observations);
    return 0;
}
