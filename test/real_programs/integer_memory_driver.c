#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

extern uint64_t integer_memory_24(void *, void *, uint64_t);
extern uint64_t integer_memory_40(void *, void *, uint64_t);
extern uint64_t integer_memory_56(void *, void *, uint64_t);
extern uint64_t integer_memory_65(void *, void *, uint64_t);
extern uint64_t integer_memory_96(void *, void *, uint64_t);

__attribute__((noinline)) uint64_t integer_memory_clobber(uint64_t value) {
    const uint64_t result = value * UINT64_C(0x9e3779b97f4a7c15) + 1;
    __asm__ volatile(
        "mov $17, %%rax\n\tmov $23, %%rcx\n\tmov $31, %%rdx\n\t"
        "mov $43, %%rsi\n\tmov $59, %%rdi\n\tmov $61, %%r8\n\tmov $71, %%r9\n\t"
        "mov $83, %%r10\n\tmov $97, %%r11\n\tpxor %%xmm0, %%xmm0\n\t"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "xmm0", "memory", "cc");
    return result;
}

int main(void) {
    const size_t page = (size_t)sysconf(_SC_PAGESIZE);
    unsigned char *source = mmap(0, page * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    unsigned char *output = mmap(0, page * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (source == MAP_FAILED || output == MAP_FAILED || mprotect(source + page, page, PROT_NONE) || mprotect(output + page, page, PROT_NONE)) return 90;
    typedef uint64_t (*Function)(void *, void *, uint64_t);
    const Function functions[] = {integer_memory_24, integer_memory_40, integer_memory_56, integer_memory_65, integer_memory_96};
    const unsigned widths[] = {24, 40, 56, 65, 96};
    uint64_t state = UINT64_C(0xa510c72e83b946df);
    unsigned observations = 0;
    for (unsigned i = 0; i < 256; ++i) {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17;
        for (unsigned f = 0; f < 5; ++f) {
            const unsigned width = widths[f], bytes = (width + 7) / 8;
            unsigned char *in = source + page - bytes, *out = output + page - bytes;
            for (unsigned j = 0; j < bytes; ++j) in[j] = i % 8 == 0 ? 255 : (unsigned char)((state >> ((j % 8) * 8)) + j * 29);
            memset(out - 16, 0x5a, bytes + 16);
            unsigned __int128 value = 0;
            for (unsigned j = 0; j < bytes; ++j) value |= (unsigned __int128)in[j] << (8 * j);
            const unsigned __int128 mask = ((unsigned __int128)1 << width) - 1;
            const unsigned __int128 changed = (value ^ 173) & mask;
            const uint64_t fold = (uint64_t)changed ^ (uint64_t)(changed >> 64);
            const uint64_t clobbered = state * UINT64_C(0x9e3779b97f4a7c15) + 1;
            const uint64_t actual = functions[f](in, out, state);
            if (actual != (fold ^ clobbered)) {
                fprintf(stderr, "integer-memory i=%u width=%u actual=%016llx expected=%016llx last_in=%02x last_out=%02x\n", i, width, (unsigned long long)actual, (unsigned long long)(fold ^ clobbered), in[bytes - 1], out[bytes - 1]);
                return 1 + f;
            }
            for (unsigned j = 0; j < bytes; ++j) {
                const unsigned char defined = j + 1 == bytes && width % 8 ? (unsigned char)((1u << (width % 8)) - 1) : 255;
                if ((out[j] & defined) != ((unsigned char)(changed >> (8 * j)) & defined)) return 11 + f;
            }
            for (unsigned j = 0; j < 16; ++j) if (out[-16 + (int)j] != 0x5a) return 21 + f;
            ++observations;
        }
    }
    if (munmap(source, page * 2) || munmap(output, page * 2)) return 91;
    printf("integer-memory observations=%u exact=padding=clobbers=guards=preserved\n", observations);
    return 0;
}
