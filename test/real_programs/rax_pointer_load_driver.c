#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#define DECLARE(name) extern uint64_t name(void *, uint64_t, uint64_t, uint64_t, uint64_t *)
DECLARE(rax_load_u8);
DECLARE(rax_load_u16);
DECLARE(rax_load_u32);
DECLARE(rax_load_u64);
DECLARE(rax_load_pointer);
DECLARE(rax_load_called);
DECLARE(rax_load_loop);
typedef uint64_t (*Probe)(void *, uint64_t, uint64_t, uint64_t, uint64_t *);

__attribute__((noinline)) void *rax_load_helper(void **slot) {
    void *pointer = *slot;
    __asm__ volatile (
        "mov $17, %%rax\n\tmov $19, %%rcx\n\tmov $23, %%rdx\n\t"
        "mov $29, %%rsi\n\tmov $31, %%rdi\n\tmov $37, %%r8\n\t"
        "mov $41, %%r9\n\tmov $43, %%r10\n\tmov $47, %%r11"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc", "memory");
    return pointer;
}

int main(void) {
    const long page = sysconf(_SC_PAGESIZE);
    if (page < 64) return 100;
    unsigned char *mapping = mmap(NULL, (size_t)page * 2, PROT_READ | PROT_WRITE,
        MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mapping == MAP_FAILED || mprotect(mapping + page, (size_t)page, PROT_NONE)) return 101;
    const uint64_t values[] = {0, 1, 0x80, 0x8000, UINT64_C(0x80000000),
        UINT64_C(0x8000000000000000), UINT64_C(0x123456789abcdef0), UINT64_MAX};
    const uint64_t takes[] = {0, 1, 2, 7, UINT64_MAX, UINT64_C(0x8000000000000000),
        UINT64_C(0x123456789abcdef0), UINT64_C(0x2000000000000001)};
    const Probe functions[] = {rax_load_u8, rax_load_u16, rax_load_u32,
        rax_load_u64, rax_load_pointer, rax_load_called};
    const unsigned widths[] = {1, 2, 4, 8, 8, 8};
    const unsigned live_pointer[] = {0, 1, 0, 1, 1, 1};
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned v = 0; v < 8; ++v) for (unsigned t = 0; t < 8; ++t) {
        const uint64_t left = UINT64_C(0x9876543210fedcba) + v * 17;
        const uint64_t right = UINT64_C(0x0123456789abcdef) ^ (t * 257);
        for (unsigned f = 0; f < 6; ++f) {
            const unsigned width = widths[f];
            void *pointer = mapping + page - width;
            memcpy(pointer, &values[v], width);
            const uint64_t mask = width == 8 ? UINT64_MAX : (UINT64_C(1) << (width * 8)) - 1;
            const uint64_t loaded = takes[t] ? values[v] & mask : 0;
            const uint64_t expected = loaded ^ left ^ right ^ takes[t];
            const uint64_t observed = loaded ^ (takes[t] && live_pointer[f] ? (uintptr_t)pointer : 0);
            uint64_t output[] = {guard, ~observed, guard};
            /* A skipped branch must not touch even the null pointer slot.
             * A taken branch must not read beyond the exact requested width. */
            const uint64_t actual = functions[f](takes[t] ? &pointer : NULL, takes[t], left, right, &output[1]);
            if (actual != expected || output[1] != observed || output[0] != guard || output[2] != guard) {
                fprintf(stderr, "RAX load mismatch function=%u value=%u take=%u\n", f, v, t);
                return 1;
            }
            uint64_t unchanged = 0;
            memcpy(&unchanged, pointer, width);
            if (unchanged != (values[v] & mask)) return 2;
            ++observations;
        }
        uint64_t storage[60], original[60];
        for (unsigned word = 0; word < 60; ++word) storage[word] = guard ^ word;
        unsigned char *base = (unsigned char *)(storage + 2);
        uint64_t sum = left;
        for (unsigned index = 0; index < 8; ++index) {
            const uint32_t element = (uint32_t)(values[v] + index * UINT64_C(0x10203));
            memcpy(base + index * 56, &element, sizeof element);
            if (index < t) sum += (uint64_t)element ^ (uintptr_t)(base + index * 56);
        }
        memcpy(original, storage, sizeof storage);
        uint64_t output[] = {guard, ~sum, guard};
        if (rax_load_loop(t ? base : NULL, t, left, right, &output[1]) != (sum ^ right) ||
            output[1] != sum || output[0] != guard || output[2] != guard ||
            memcmp(storage, original, sizeof storage)) return 3;
        ++observations;
    }
    if (munmap(mapping, (size_t)page * 2)) return 102;
    printf("rax-pointer-load observations=%u widths=pointer=branches=loops=calls=live=guards=preserved\n", observations);
    return 0;
}
