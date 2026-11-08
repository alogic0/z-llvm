#define _GNU_SOURCE
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

extern unsigned char sc_data[128];
extern uint64_t symbolic_direct(uint64_t);
extern uint64_t symbolic_indirect(void *, uint64_t);
extern uint64_t symbolic_negative(uint64_t);
extern uint64_t symbolic_stack(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
extern uint64_t symbolic_live(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, double *, double);
extern long symbolic_write(long, long);
extern long symbolic_read(long, long, long);
static unsigned bad_address;

/* Force callers to preserve their live integer and floating values. */
#define CLOBBER() __asm__ volatile ( \
    "xor %%eax, %%eax; xor %%ecx, %%ecx; xor %%edx, %%edx; xor %%esi, %%esi; xor %%edi, %%edi;" \
    "xor %%r8d, %%r8d; xor %%r9d, %%r9d; xor %%r10d, %%r10d; xor %%r11d, %%r11d;" \
    "pxor %%xmm0, %%xmm0; pxor %%xmm1, %%xmm1; pxor %%xmm2, %%xmm2; pxor %%xmm3, %%xmm3;" \
    "pxor %%xmm4, %%xmm4; pxor %%xmm5, %%xmm5; pxor %%xmm6, %%xmm6; pxor %%xmm7, %%xmm7;" \
    "pxor %%xmm8, %%xmm8; pxor %%xmm9, %%xmm9; pxor %%xmm10, %%xmm10; pxor %%xmm11, %%xmm11;" \
    "pxor %%xmm12, %%xmm12; pxor %%xmm13, %%xmm13; pxor %%xmm14, %%xmm14; pxor %%xmm15, %%xmm15;" \
    ::: "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", \
    "xmm0", "xmm1", "xmm2", "xmm3", "xmm4", "xmm5", "xmm6", "xmm7", \
    "xmm8", "xmm9", "xmm10", "xmm11", "xmm12", "xmm13", "xmm14", "xmm15", "cc", "memory")

__attribute__((noinline)) uint64_t sc_mix(uint64_t first, uint64_t seed, uint64_t last) {
    if (first != (uintptr_t)&sc_data[17] || last != (uintptr_t)&sc_data[31]) { bad_address = 1; return 0; }
    uint64_t value = (seed + *(unsigned char *)(uintptr_t)first) ^ *(unsigned char *)(uintptr_t)last;
    CLOBBER();
    return value;
}

__attribute__((noinline)) uint64_t sc_negative(uint64_t address, uint64_t seed) {
    if (address + 8 != (uintptr_t)sc_data) { bad_address = 1; return 0; }
    uint64_t value = seed ^ sc_data[0];
    CLOBBER();
    return value;
}

static uint64_t many_expected(uint64_t a, uint64_t b, uint64_t c, uint64_t d, uint64_t e, uint64_t f) {
    return (a + 3*b + 5*c + 7*d + 11*e + 13*f) ^ (sc_data[0] + 17*sc_data[17] + 31*sc_data[31]);
}

__attribute__((noinline)) uint64_t sc_many(uint64_t a, uint64_t b, uint64_t c, uint64_t d, uint64_t e, uint64_t f,
                                        uint64_t first, uint64_t middle, uint64_t last) {
    if (first != (uintptr_t)sc_data || middle != (uintptr_t)&sc_data[17] || last != (uintptr_t)&sc_data[31]) { bad_address = 1; return 0; }
    uint64_t value = many_expected(a, b, c, d, e, f);
    CLOBBER();
    return value;
}

int main(void) {
    FILE *file = tmpfile();
    if (!file) return 1;
    int fd = fileno(file);
    unsigned observations = 0;
    for (unsigned i = 0; i < 128; ++i) {
        for (unsigned j = 0; j < 128; ++j) sc_data[j] = (unsigned char)(i*37 + j*19);
        uint64_t a = UINT64_C(0xfedcba9876543210) + i, b = a ^ (i+31), c = ~a;
        uint64_t d = a*17, e = a+123, f = b*31;
        uint64_t mixed = (a + sc_data[17]) ^ sc_data[31];
        if (symbolic_direct(a) != mixed || symbolic_indirect((void *)sc_mix, a) != mixed ||
            symbolic_negative(a) != (a ^ sc_data[0])) return 2;
        observations += 3;
        uint64_t called = many_expected(f, e, d, c, b, a);
        if (symbolic_stack(a, b, c, d, e, f) != called) return 3;
        ++observations;
        for (unsigned choice = 0; choice < 2; ++choice) {
            uint64_t x = choice ? a : 1, y = choice ? 1 : b;
            uint64_t live_f = x ^ UINT64_C(98765);
            double fp = i*0.5 - 32;
            struct { uint64_t before; double value; uint64_t after; } output = {
                UINT64_C(0x123456789abcdef0), 0, UINT64_C(0xfedcba9876543210)
            };
            uint64_t word = x < y ? x+17 : y ^ UINT64_C(305419896);
            uint64_t all = (((x+11) ^ (y^23)) + ((c+37) ^ (d^51))) ^ ((e+67) ^ (live_f^83));
            uint64_t expected = (all + word) ^ many_expected(live_f, e, d, c, y, x);
            if (x < y) expected += x;
            if (symbolic_live(x, y, c, d, e, &output.value, fp) != expected || output.value != fp+1.25 ||
                output.before != UINT64_C(0x123456789abcdef0) || output.after != UINT64_C(0xfedcba9876543210)) return 4;
            ++observations;
        }
        size_t length = i%32 + 1;
        if (lseek(fd, 0, SEEK_SET) != 0 || ftruncate(fd, 0)) return 5;
        if (symbolic_write(fd, length) != (long)length || symbolic_write(-1, length) != -EBADF) return 6;
        observations += 2;
        unsigned char bytes[32];
        if (pread(fd, bytes, length, 0) != (long)length || memcmp(bytes, sc_data+17, length)) return 7;
        unsigned char expected[128];
        memcpy(expected, sc_data, sizeof(expected));
        memcpy(expected+80, sc_data+17, length);
        if (symbolic_read(fd, 0, length) != (long)length || memcmp(sc_data, expected, sizeof(expected))) return 8;
        ++observations;
        if (bad_address) return 9;
    }
    if (fclose(file)) return 10;
    printf("symbolic-call observations=%u addresses=aliases=stack=syscalls=live=phis=spills=preserved\n", observations);
    return 0;
}
