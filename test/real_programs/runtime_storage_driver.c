#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

extern uint64_t runtime_storage_33(void *, void *, uint64_t, uint64_t);
extern uint64_t runtime_storage_4096(void *, void *, uint64_t, uint64_t);
extern uint64_t runtime_storage_nested(void *, void *, uint64_t, uint64_t);
extern uint64_t runtime_storage_pair_array(void *, void *, uint64_t, uint64_t);

__attribute__((noinline)) uint64_t runtime_storage_observe(const unsigned char *p, uint64_t size) {
    uint64_t sum = 0;
    for (uint64_t j = 0; j < size; ++j) sum += ((uint64_t)p[j] + 1) * (j + 3);
    __asm__ volatile(
        "mov $17, %%rax\n\tmov $23, %%rcx\n\tmov $31, %%rdx\n\t"
        "mov $43, %%rsi\n\tmov $59, %%rdi\n\tmov $61, %%r8\n\tmov $71, %%r9\n\t"
        "mov $83, %%r10\n\tmov $97, %%r11\n\t"
        "pxor %%xmm0, %%xmm0\n\tpxor %%xmm1, %%xmm1\n\tpxor %%xmm2, %%xmm2\n\tpxor %%xmm3, %%xmm3\n\t"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "xmm0", "xmm1", "xmm2", "xmm3", "memory", "cc");
    return sum;
}

int main(void) {
    const size_t page = (size_t)sysconf(_SC_PAGESIZE);
    unsigned char *mapping = mmap(0, page * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (page < 4096 || mapping == MAP_FAILED || mprotect(mapping + page, page, PROT_NONE)) return 90;
    typedef uint64_t (*Function)(void *, void *, uint64_t, uint64_t);
    const Function functions[] = {runtime_storage_33, runtime_storage_4096, runtime_storage_nested, runtime_storage_pair_array};
    const size_t sizes[] = {33, 4096, 32, 16};
    uint64_t state = UINT64_C(0x7186a5b4c3d2e0f9);
    unsigned observations = 0;
    for (unsigned i = 0; i < 128; ++i) {
        for (size_t j = 0; j < page; ++j) mapping[j] = (unsigned char)(j * 53 + i * 17 + (j >> 3));
        state ^= state << 13; state ^= state >> 7; state ^= state << 17;
        for (unsigned f = 0; f < 4; ++f) {
            const size_t size = sizes[f];
            const size_t length = i == 0 ? 0 : i == 1 ? size : i == 2 ? size - 1 : (size_t)(state % (size + 1));
            unsigned char out[4160], expected[4160];
            const size_t offset = 1 + i % 15;
            memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out);
            memset(expected + offset, 0xa5, size);
            memcpy(expected + offset, mapping + page - length, length);
            uint64_t sum = 0;
            for (size_t j = 0; j < size; ++j) sum += ((uint64_t)expected[offset + j] + 1) * (j + 3);
            if (functions[f](mapping + page - length, out + offset, length, state) != (sum ^ state) || memcmp(out, expected, sizeof out)) return 1 + f;
            ++observations;
        }
    }
    if (munmap(mapping, page * 2)) return 91;
    printf("runtime-storage observations=%u lengths=padding=clobbers=guards=preserved\n", observations);
    return 0;
}
