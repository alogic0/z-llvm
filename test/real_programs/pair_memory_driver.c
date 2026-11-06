#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef unsigned __int128 U;
extern uint64_t pair_memory_capture(void *, void *, uint64_t);
extern uint64_t pair_memory_stack_capture(void *, void *, uint64_t);
extern uint64_t pair_memory_overlap(void *, void *, uint64_t);
extern uint64_t pair_memory_phi(void *, void *, void *, uint64_t);
extern void pair_memory_literal(void *);

__attribute__((noinline)) uint64_t pair_memory_mutate(void *p, uint64_t marker) {
    U replacement = ((U)marker << 64) | ~marker;
    memcpy(p, &replacement, 16);
    uint64_t result = marker ^ UINT64_C(0x123456789abcdef0);
    __asm__ volatile("xor %%eax,%%eax; xor %%edx,%%edx; xor %%ecx,%%ecx; xor %%edi,%%edi; xor %%esi,%%esi; xor %%r8d,%%r8d; xor %%r9d,%%r9d"
        ::: "rax", "rdx", "rcx", "rdi", "rsi", "r8", "r9", "cc");
    return result;
}
static uint64_t next(uint64_t *state) {
    *state ^= *state << 13; *state ^= *state >> 7; *state ^= *state << 17;
    return *state;
}
static uint64_t fold(U value) { return (uint64_t)value ^ (uint64_t)(value >> 64); }

int main(void) {
    uint64_t state = UINT64_C(0xd36fb2917e085a4c);
    unsigned observations = 0;
    for (unsigned i=0; i<256; ++i) {
        U a = (U)next(&state) << 64; a |= next(&state);
        U b = (U)next(&state) << 64; b |= next(&state);
        uint64_t marker = next(&state);
        unsigned char source[48], target[48], expected[48];
        unsigned offset = 1 + i % 15;
        memset(source, 0xa5, sizeof source); memcpy(source + offset, &a, 16);
        memset(target, 0x5a, sizeof target); memcpy(expected, target, sizeof target);
        memcpy(expected + offset, &a, 16);
        uint64_t got = pair_memory_capture(source + offset, target + offset, marker);
        if (got != (fold(a) ^ marker ^ UINT64_C(0x123456789abcdef0)) || memcmp(target, expected, sizeof target)) return 1;
        ++observations;
        memcpy(source + offset, &a, 16);
        memset(target, 0x5a, sizeof target);
        got = pair_memory_stack_capture(source + offset, target + offset, marker);
        if (got != (fold(a) ^ marker ^ UINT64_C(0x123456789abcdef0)) || memcmp(target, expected, sizeof target)) return 5;
        ++observations;
        for (int delta=-8; delta<=8; ++delta) {
            memset(source, 0xa5, sizeof source); memcpy(source + 16, &a, 16);
            memcpy(expected, source, sizeof source); memmove(expected + 16 + delta, expected + 16, 16);
            got = pair_memory_overlap(source + 16, source + 16 + delta, marker);
            if (got != (fold(a) ^ marker) || memcmp(source, expected, sizeof source)) return 2;
            ++observations;
        }
        memcpy(source + offset, &a, 16);
        U chosen = (marker & 1) ? a - b : a + b;
        memset(target, 0x5a, sizeof target); memcpy(expected, target, sizeof target);
        memcpy(expected + offset, &chosen, 16);
        got = pair_memory_phi(source + offset, &b, target + offset, marker);
        if (got != (fold(chosen) ^ marker ^ UINT64_C(0x123456789abcdef0)) || memcmp(target, expected, sizeof target)) return 3;
        ++observations;
        U literal = ((U)UINT64_C(0x8000000000000001) << 64) | 1;
        memset(target, 0x5a, sizeof target); memcpy(expected, target, sizeof target);
        memcpy(expected + offset, &literal, 16);
        pair_memory_literal(target + offset);
        if (memcmp(target, expected, sizeof target)) return 4;
        ++observations;
    }
    printf("pair-memory observations=%u unaligned=checked overlap=checked calls=checked phi=checked\n", observations);
    return 0;
}
