#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

extern uint32_t vector_mask_compare16(void *, uint8_t, void *);
extern uint32_t vector_mask_compare8(void *, uint8_t, void *);
extern uint32_t vector_mask_unpack16(uint32_t, void *);
extern uint64_t vector_mask_nibbles(uint64_t, void *);
extern unsigned __int128 vector_mask_reverse128(uint64_t, uint64_t, void *);
extern uint32_t vector_mask_three(uint32_t, void *);
extern uint64_t vector_mask_live(void *, void *, void *, uint64_t);
extern uint64_t vector_mask_reverse8(uint64_t);
extern uint64_t vector_mask_returned8(uint64_t);

__attribute__((noinline)) uint64_t vector_mask_clobber(void) {
    __asm__ volatile(
        "xor %%eax,%%eax; xor %%edx,%%edx; xor %%ecx,%%ecx; xor %%edi,%%edi; xor %%esi,%%esi; xor %%r8d,%%r8d; xor %%r9d,%%r9d;"
        "pxor %%xmm0,%%xmm0; pxor %%xmm1,%%xmm1; pxor %%xmm2,%%xmm2; pxor %%xmm3,%%xmm3"
        ::: "rax", "rdx", "rcx", "rdi", "rsi", "r8", "r9", "xmm0", "xmm1", "xmm2", "xmm3", "cc");
    return UINT64_C(0x9a34f1628b05dc7e);
}
__attribute__((noinline)) uint64_t vector_mask_return(uint64_t value) {
    vector_mask_clobber();
    return value ^ UINT64_C(0xc5397b06ea8124df);
}
static uint64_t next(uint64_t *state) {
    *state ^= *state << 13;
    *state ^= *state >> 7;
    *state ^= *state << 17;
    return *state;
}
int main(void) {
    const size_t page = (size_t)sysconf(_SC_PAGESIZE);
    unsigned char *mapping = mmap(0, page * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mapping == MAP_FAILED || mprotect(mapping + page, page, PROT_NONE)) return 90;
    uint64_t state = UINT64_C(0xc5d89a134f2670be);
    unsigned observations = 0;
    for (unsigned i = 0; i < 256; ++i) {
        unsigned char bytes[16], right[16], out[48], expected[48];
        const uint64_t lo = next(&state), hi = next(&state);
        for (unsigned j = 0; j < 16; ++j) {
            bytes[j] = next(&state);
            right[j] = next(&state);
        }
        const uint8_t needle = i;
        for (unsigned j = 0; j < 16; ++j) if ((i >> (j % 8)) & 1) bytes[j] = needle;
        const unsigned offset = 1 + i % 15;
        for (unsigned n = 8; n <= 16; n += 8) {
            uint32_t mask = 0;
            for (unsigned j = 0; j < n; ++j) if (bytes[j] == needle) mask |= 1u << j;
            memcpy(mapping + page - n, bytes, n);
            memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out);
            for (unsigned j = 0; j < n / 8; ++j) expected[offset + j] = (uint8_t)(mask >> (8 * j));
            const uint32_t actual = n == 8 ? vector_mask_compare8(mapping + page - n, needle, out + offset) : vector_mask_compare16(mapping + page - n, needle, out + offset);
            if (actual != mask || memcmp(out, expected, sizeof out)) return 1;
            ++observations;
        }
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out);
        for (unsigned j = 0; j < 16; ++j) expected[offset + j] = (uint8_t)((lo >> j) & 1);
        if (vector_mask_unpack16((uint32_t)lo, out + offset) != (uint16_t)lo || memcmp(out, expected, sizeof out)) return 2;
        ++observations;
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out);
        for (unsigned j = 0; j < 16; ++j) expected[offset + j] = (uint8_t)((lo >> (j * 4)) & 15);
        if (vector_mask_nibbles(lo, out + offset) != lo || memcmp(out, expected, sizeof out)) return 3;
        ++observations;
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out);
        memcpy(expected + offset, &lo, 8); memcpy(expected + offset + 8, &hi, 8);
        const unsigned __int128 reversed = (unsigned __int128)(uint32_t)lo << 96 |
            (unsigned __int128)(uint32_t)(lo >> 32) << 64 |
            (unsigned __int128)(uint32_t)hi << 32 | (uint32_t)(hi >> 32);
        if (vector_mask_reverse128(lo, hi, out + offset) != reversed || memcmp(out, expected, sizeof out)) return 4;
        ++observations;
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out);
        for (unsigned j = 0; j < 3; ++j) expected[offset + j] = (uint8_t)((lo >> j) & 1);
        if (vector_mask_three((uint32_t)lo, out + offset) != (lo & 7) || memcmp(out, expected, sizeof out)) return 5;
        ++observations;
        uint32_t mask = 0;
        for (unsigned j = 0; j < 16; ++j) if (bytes[j] < right[j]) mask |= 1u << j;
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out);
        expected[offset] = (uint8_t)mask; expected[offset + 1] = (uint8_t)(mask >> 8);
        if (vector_mask_live(bytes, right, out + offset, lo) != ((lo + mask) ^ UINT64_C(0x9a34f1628b05dc7e)) || memcmp(out, expected, sizeof out)) return 6;
        ++observations;
        if (vector_mask_reverse8(lo) != __builtin_bswap64(lo)) return 7;
        ++observations;
        const uint64_t returned = lo ^ UINT64_C(0xc5397b06ea8124df);
        if (vector_mask_returned8(lo) != (__builtin_bswap64(returned) ^ returned)) return 8;
        ++observations;
    }
    if (munmap(mapping, page * 2)) return 91;
    printf("vector-masks observations=%u bits=lanes=roundtrips=clobbers=guards=preserved\n", observations);
    return 0;
}
