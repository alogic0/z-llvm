#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

extern void runtime_memory_f32(void *, void *, void *);
extern void runtime_memory_f64(void *, void *, void *);
extern void runtime_memory_returned(void *, void *, uint64_t);
extern void runtime_memory_pressure(void *, void *, double, double, double, double, double, double, double, double);
extern uint64_t runtime_memory_memset(void *, uint64_t, uint8_t);
extern uint64_t runtime_memory_allocation(uint64_t, uint64_t, uint64_t, uint64_t);
extern float runtime_memory_nneg(uint8_t);

__attribute__((noinline)) void runtime_memory_clobber(void) {
    __asm__ volatile("pxor %%xmm0, %%xmm0\n\tpxor %%xmm1, %%xmm1\n\t"
                     "pxor %%xmm2, %%xmm2\n\tpxor %%xmm3, %%xmm3\n\t"
                     "pxor %%xmm4, %%xmm4\n\tpxor %%xmm5, %%xmm5\n\t"
                     "pxor %%xmm6, %%xmm6\n\tpxor %%xmm7, %%xmm7\n\t"
                     "xor %%eax, %%eax\n\txor %%ecx, %%ecx\n\txor %%edx, %%edx\n\t"
                     "xor %%esi, %%esi\n\txor %%edi, %%edi\n\txor %%r8d, %%r8d\n\t"
                     "xor %%r9d, %%r9d\n\txor %%r10d, %%r10d\n\txor %%r11d, %%r11d"
                     : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11",
                     "xmm0", "xmm1", "xmm2", "xmm3", "xmm4", "xmm5", "xmm6", "xmm7", "cc", "memory");
}
__attribute__((noinline)) void *runtime_memory_identity(void *p) { runtime_memory_clobber(); return p; }
void *runtime_memory_allocate(uint64_t size, uint64_t fail) { return fail ? NULL : malloc(size); }
void *runtime_memory_resize(void *p, uint64_t size, uint64_t fail) { return fail ? NULL : realloc(p, size); }
void runtime_memory_release(void *p) { free(p); }

static int guards(const unsigned char *p, size_t start, size_t size, size_t total) {
    for (size_t i = 0; i < total; ++i)
        if ((i < start || i >= start + size) && p[i] != 0xa5) return 0;
    return 1;
}

int main(void) {
    const uint64_t special[] = {0, UINT64_C(0x8000000000000000), 1, UINT64_C(0x000fffffffffffff),
        UINT64_C(0x7ff0000000000000), UINT64_C(0xfff0000000000000), UINT64_C(0x7ff8123456789abc),
        UINT64_C(0x7ff0000000000001), UINT64_C(0xffffffffffffffff)};
    const uint32_t single_special[] = {0, 0x80000000U, 1, 0x007fffffU, 0x00800000U,
        0x7f7fffffU, 0x7f800000U, 0xff800000U, 0x7fc12345U, 0x7f800001U};
    unsigned observations = 0;
    for (unsigned i = 0; i < 128; ++i) {
        unsigned char input[64], output[112], kept[64], expected[16];
        uint64_t bits[9];
        for (unsigned lane = 0; lane < 9; ++lane)
            bits[lane] = i < 64 ? special[(i + lane) % 9] : UINT64_C(0x9e3779b97f4a7c15) * (i * 9 + lane);
        const unsigned offset = 1 + i % 7;
        const uint32_t single[2] = {single_special[i % 10], single_special[(i + 3) % 10]};
        memset(input, 0xa5, sizeof(input)); memcpy(input + offset, single, 8);
        memset(output, 0xa5, sizeof(output)); memset(kept, 0xa5, sizeof(kept));
        memcpy(expected, input + offset + 4, 4); memcpy(expected + 4, input + offset, 4);
        runtime_memory_f32(input + offset, output + offset, kept + offset);
        if (memcmp(output + offset, expected, 8) || memcmp(kept + offset, single, 8) ||
            !guards(output, offset, 8, sizeof(output)) || !guards(kept, offset, 8, sizeof(kept))) return 1;
        ++observations;
        // Aliasing output with input must still preserve both original loads.
        memset(kept, 0xa5, sizeof(kept));
        runtime_memory_f32(input + offset, input + offset, kept + offset);
        if (memcmp(input + offset, expected, 8) || memcmp(kept + offset, single, 8)) return 2;
        ++observations;
        memcpy(input + offset, bits, 16); memset(kept, 0xa5, sizeof(kept));
        memcpy(expected, bits + 1, 8); memcpy(expected + 8, bits, 8);
        runtime_memory_f64(input + offset, input + offset, kept + offset);
        if (memcmp(input + offset, expected, 16) || memcmp(kept + offset, bits, 16) ||
            !guards(input, offset, 16, sizeof(input)) || !guards(kept, offset, 16, sizeof(kept))) return 3;
        ++observations;
        memset(output, 0xa5, sizeof(output)); memcpy(input + offset, bits, 16);
        runtime_memory_returned(input, output + offset, offset);
        if (memcmp(output + offset, bits, 8) || !guards(output, offset, 8, sizeof(output))) return 4;
        ++observations;
        double values[8]; memcpy(values, bits, sizeof(values));
        memset(output, 0xa5, sizeof(output)); memcpy(input + offset, bits + 8, 8);
        runtime_memory_pressure(input + offset, output + offset,
            values[0], values[1], values[2], values[3], values[4], values[5], values[6], values[7]);
        if (memcmp(output + offset, bits, 72) || !guards(output, offset, 72, sizeof(output))) return 5;
        ++observations;
        const unsigned length = i % 65;
        const uint8_t fill = (uint8_t)(i * 73);
        memset(output, 0xa5, sizeof(output));
        if (runtime_memory_memset(output + offset, length, fill) != length ||
            !guards(output, offset, length, sizeof(output))) return 6;
        for (unsigned j = 0; j < length; ++j) if (output[offset + j] != fill) return 7;
        ++observations;
        for (unsigned fail_alloc = 0; fail_alloc < 2; ++fail_alloc)
            for (unsigned fail_resize = 0; fail_resize < 2; ++fail_resize) {
                const uint64_t want = fail_alloc ? UINT64_MAX : fail_resize ? ~bits[0] : bits[0];
                if (runtime_memory_allocation(16 + i, bits[0], fail_alloc, fail_resize) != want) return 8;
                ++observations;
            }
        if (runtime_memory_nneg((uint8_t)i) != (float)i) return 9;
        ++observations;
    }
    // A wider read or write at these exact-width boundaries faults immediately.
    const long page = sysconf(_SC_PAGESIZE);
    if (page < 128) return 10;
    unsigned char *p = mmap(NULL, (size_t)page * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (p == MAP_FAILED || mprotect(p + page, (size_t)page, PROT_NONE)) return 11;
    unsigned char kept[16];
    const uint64_t original[2] = {UINT64_C(0x7ff0000000000001), UINT64_C(0xfff8123456789abc)};
    memcpy(p + page - 8, original, 8);
    runtime_memory_f32(p + page - 8, p + page - 8, kept);
    if (memcmp(kept, original, 8)) return 12;
    ++observations;
    memcpy(p + page - 16, original, 16);
    runtime_memory_f64(p + page - 16, p + page - 16, kept);
    if (memcmp(kept, original, 16)) return 13;
    ++observations;
    if (runtime_memory_memset(p + page - 16, 16, 0x93) != 16) return 14;
    for (unsigned i = 0; i < 16; ++i) if (p[page - 16 + i] != 0x93) return 15;
    ++observations;
    if (munmap(p, (size_t)page * 2)) return 16;
    printf("runtime-memory observations=%u widths=exact aliases=preserved allocation-errors=checked guards=preserved\n", observations);
    return observations == 1411 ? 0 : 17;
}
