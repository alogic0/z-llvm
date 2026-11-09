#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern uint64_t undefined_select_1(uint64_t, uint64_t, uint64_t, void *);
extern uint64_t undefined_select_8(uint64_t, uint64_t, uint64_t, void *);
extern uint64_t undefined_select_16(uint64_t, uint64_t, uint64_t, void *);
extern uint64_t undefined_select_32(uint64_t, uint64_t, uint64_t, void *);
extern uint64_t undefined_select_64(uint64_t, uint64_t, uint64_t, void *);
extern uint64_t undefined_select_128(uint64_t, uint64_t, uint64_t, void *);
extern void *undefined_select_pointer(void *, void *, uint64_t, void *);

static void clobber(void) {
    __asm__ volatile(
        "mov $17, %%rax\n\tmov $23, %%rcx\n\tmov $31, %%rdx\n\t"
        "mov $43, %%rsi\n\tmov $59, %%rdi\n\tmov $61, %%r8\n\tmov $71, %%r9\n\t"
        "mov $83, %%r10\n\tmov $97, %%r11\n\tpxor %%xmm0, %%xmm0\n\t"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "xmm0", "memory", "cc");
}
__attribute__((noinline)) uint64_t undefined_select_clobber(uint64_t value) {
    const uint64_t result = value * UINT64_C(0x517cc1b727220a95) + 17;
    clobber();
    return result;
}
__attribute__((noinline)) void *undefined_select_pointer_clobber(void *value) {
    clobber();
    return value;
}

int main(void) {
    typedef uint64_t (*Function)(uint64_t, uint64_t, uint64_t, void *);
    const Function functions[] = {undefined_select_1, undefined_select_8, undefined_select_16, undefined_select_32, undefined_select_64, undefined_select_128};
    const unsigned widths[] = {1, 8, 16, 32, 64, 128};
    unsigned char pool[64];
    uint64_t state = UINT64_C(0x86945a3c1f20b7de);
    unsigned observations = 0;
    for (unsigned i = 0; i < 128; ++i) {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17;
        const uint64_t a = i % 8 ? state : UINT64_MAX, b = state ^ UINT64_C(0x5a3cc369d278e104);
        const uint64_t flag = i % 3 == 0 ? 0 : i % 3 == 1 ? 1 : UINT64_C(0x8000000000000000);
        const unsigned offset = 1 + i % 15;
        for (unsigned f = 0; f < 6; ++f) {
            unsigned char output[64], expected[64];
            memset(output, 0x5a, sizeof output); memcpy(expected, output, sizeof output);
            uint64_t folded;
            if (widths[f] == 128) {
                const uint64_t pair[2] = {a, b};
                memcpy(expected + offset, pair, sizeof pair);
                folded = a ^ b;
            } else {
                const uint64_t value = widths[f] == 64 ? a : a & ((UINT64_C(1) << widths[f]) - 1);
                memcpy(expected + offset, &value, sizeof value);
                folded = value;
            }
            const uint64_t result = (folded * UINT64_C(0x517cc1b727220a95) + 17) ^ b;
            if (functions[f](a, b, flag, output + offset) != result || memcmp(output, expected, sizeof output)) return 1 + f;
            ++observations;
        }
        unsigned char output[64], expected[64];
        void *pointer = i % 5 ? pool + i % 32 : 0;
        void *neighbor = pool + 40;
        memset(output, 0x5a, sizeof output); memcpy(expected, output, sizeof output);
        memcpy(expected + offset, &pointer, sizeof pointer);
        if (undefined_select_pointer(pointer, neighbor, flag, output + offset) != pointer || memcmp(output, expected, sizeof output)) return 7;
        ++observations;
    }
    printf("undefined-selects observations=%u defined=conditions=clobbers=guards=preserved\n", observations);
    return 0;
}
