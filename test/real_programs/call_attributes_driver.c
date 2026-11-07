#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

extern uint64_t attributes_copy(void *, const void *, uint64_t, uint64_t);
extern uint64_t attributes_move(void *, const void *, uint64_t, uint64_t);
extern uint64_t attributes_write(void *, uint32_t, uint64_t);
extern uint32_t attributes_range32(int32_t, uint32_t);
extern uint64_t attributes_range64(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);

__attribute__((noinline)) static void clobber(void) {
    __asm__ volatile("xor %%eax, %%eax; xor %%ecx, %%ecx; xor %%edx, %%edx;"
                     "xor %%esi, %%esi; xor %%edi, %%edi; xor %%r8d, %%r8d;"
                     "xor %%r9d, %%r9d; xor %%r10d, %%r10d; xor %%r11d, %%r11d"
                     : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc", "memory");
}
void attributes_touch(void *p, uint32_t value) { clobber(); memcpy(p, &value, 4); }
void *attributes_identity(void *p) { clobber(); return p; }
int32_t attributes_i32(int32_t value) { clobber(); return value; }
uint64_t attributes_i64(uint64_t value) { clobber(); return value; }

int main(void) {
    unsigned observations = 0;
    unsigned char source[160], actual[160], expected[160];
    const uint64_t cookie = UINT64_C(0xa5b6c7d8e9f01234);
    for (unsigned n = 0; n <= 64; ++n) for (unsigned offset = 0; offset < 8; ++offset) {
        for (unsigned i = 0; i < sizeof(source); ++i) source[i] = (unsigned char)(i * 37 + n);
        memset(actual, 0xa5, sizeof(actual));
        memcpy(expected, actual, sizeof(actual));
        memcpy(expected + 16 + offset, source + 24 + offset, n);
        if (attributes_copy(actual + 16 + offset, source + 24 + offset, n, cookie) != (cookie ^ n) ||
            memcmp(actual, expected, sizeof(actual))) return 1;
        ++observations;
        for (unsigned direction = 0; direction < 3; ++direction) {
            memcpy(actual, source, sizeof(actual));
            memcpy(expected, source, sizeof(expected));
            unsigned from = 32 + offset;
            unsigned to = from + (direction == 0 ? 3 : direction == 1 ? -3 : 0);
            memmove(expected + to, expected + from, n);
            if (attributes_move(actual + to, actual + from, n, cookie) != (cookie ^ n) ||
                memcmp(actual, expected, sizeof(actual))) return 2;
            ++observations;
        }
    }
    for (unsigned i = 0; i < 256; ++i) {
        uint32_t value = UINT32_C(0xdead0000) ^ (i * UINT32_C(0x10101));
        memset(actual, 0xa5, sizeof(actual));
        memcpy(expected, actual, sizeof(actual));
        memcpy(expected + 16 + i % 8, &value, 4);
        if (attributes_write(actual + 16 + i % 8, value, cookie) != (cookie ^ value) ||
            memcmp(actual, expected, sizeof(actual))) return 3;
        ++observations;
    }
    for (int i = -16; i < 16; ++i) {
        if (attributes_range32(i, (uint32_t)cookie) != ((uint32_t)i ^ (uint32_t)cookie)) return 4;
        ++observations;
        uint64_t v = (uint64_t)(int64_t)i;
        uint64_t result = ((((v ^ cookie) + 7) ^ (cookie >> 3)) + UINT64_C(0x8000000000000000)) ^ 123;
        if (attributes_range64(v, cookie, 7, cookie >> 3, UINT64_C(0x8000000000000000), 123) != result) return 5;
        ++observations;
    }
    long page = sysconf(_SC_PAGESIZE);
    if (page <= 64) return 6;
    unsigned char *left = mmap(NULL, (size_t)page * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    unsigned char *right = mmap(NULL, (size_t)page * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (left == MAP_FAILED || right == MAP_FAILED || mprotect(left + page, (size_t)page, PROT_NONE) ||
        mprotect(right + page, (size_t)page, PROT_NONE)) return 7;
    for (unsigned n = 0; n <= 64; ++n) {
        unsigned char *dst = left + page - n, *src = right + page - n;
        memset(src, 0x5a, n);
        memset(dst, 0xa5, n);
        if (attributes_copy(dst, src, n, cookie) != (cookie ^ n) || memcmp(dst, src, n)) return 8;
        ++observations;
    }
    if (munmap(left, (size_t)page * 2) || munmap(right, (size_t)page * 2)) return 9;
    if (observations != 2465) return 10;
    puts("call-attributes observations=2465 ranges=wrapped calls=preserved overlap=checked guards=preserved");
    return 0;
}
