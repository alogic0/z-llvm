#include <stdint.h>
#include <stdio.h>
#include <string.h>
extern uint64_t large_cfg_chain_64(uint64_t, uint64_t, void *);
extern uint64_t large_cfg_chain_32(uint64_t, uint64_t, void *);
extern uint64_t large_cfg_labels_64(uint64_t, uint64_t, void *);
extern uint64_t large_cfg_labels_32(uint64_t, uint64_t, void *);
extern uint64_t large_cfg_switch(uint64_t, uint64_t, void *);
extern void *large_cfg_anchor_64[1], *large_cfg_anchor_32[1];
static uint64_t noise(uint64_t x) { return x * UINT64_C(0x9e3779b97f4a7c15) + 1; }
__attribute__((noinline)) uint64_t large_cfg_noise(uint64_t x) {
    const uint64_t result = noise(x);
    __asm__ volatile("mov $17, %%rax; mov $23, %%rcx; mov $31, %%rdx; mov $43, %%rsi; mov $59, %%rdi; mov $61, %%r8; mov $71, %%r9; mov $83, %%r10; mov $97, %%r11; pxor %%xmm0, %%xmm0"
        ::: "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "xmm0", "memory", "cc");
    return result;
}
typedef uint64_t (*Function)(uint64_t, uint64_t, void *);
static int check(Function function, unsigned kind, uint64_t key, uint64_t seed) {
    unsigned char memory[40]; memset(memory, 0xa5, sizeof memory);
    const unsigned narrow = kind == 1 || kind == 3, bytes = narrow ? 4 : 8;
    uint64_t value = noise(seed);
    if (kind < 2) {
        uint64_t additions = UINT64_C(2046) * 2047 / 2;
        if (kind == 0) {
            additions = 20974;
            for (unsigned j = 64; j < 20974; j += 64) additions += j;
        }
        value += additions;
    } else if (kind < 4) value = (key & 1) ? value ^ 91 : value + 17;
    else value = key <= 1025 ? value + ((key < 1024 ? key : 0) * 37 + 7) : value ^ UINT64_C(1073741823);
    if (narrow) value = (uint32_t)value;
    const uint64_t expected = narrow ? (uint32_t)(value ^ seed) : value ^ seed;
    const uint64_t actual = function(key, seed, memory + 16);
    if (actual != expected) {
        fprintf(stderr, "large-cfg kind=%u key=%llu actual=%llx expected=%llx\n", kind, (unsigned long long)key, (unsigned long long)actual, (unsigned long long)expected);
        return 1;
    }
    for (unsigned j = 0; j < sizeof memory; ++j) {
        unsigned char expected_byte = j >= 16 && j < 16 + bytes ? (unsigned char)(value >> ((j - 16) * 8)) : 0xa5;
        if (kind < 2 && j >= 24 && j < 32) {
            const uintptr_t anchor = (uintptr_t)(kind ? large_cfg_anchor_32[0] : large_cfg_anchor_64[0]);
            expected_byte = (unsigned char)(anchor >> ((j - 24) * 8));
        }
        if (memory[j] != expected_byte) return 2;
    }
    return 0;
}
int main(void) {
    if (!large_cfg_anchor_64[0] || !large_cfg_anchor_32[0]) return 80;
    const Function functions[] = {large_cfg_chain_64, large_cfg_chain_32, large_cfg_labels_64, large_cfg_labels_32};
    unsigned observations = 0;
    uint64_t seed = UINT64_C(0xa510c72e83b946df);
    for (unsigned i = 0; i < 128; ++i) {
        seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17;
        for (unsigned kind = 0; kind < 4; ++kind) {
            if (check(functions[kind], kind, i, seed)) return 1 + kind;
            ++observations;
        }
    }
    for (unsigned i = 0; i < 2112; ++i) {
        const uint64_t key = i < 2048 ? i : (UINT64_C(1) << 32) + i - 2048;
        seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17;
        if (check(large_cfg_switch, 4, key, seed)) return 9;
        ++observations;
    }
    printf("large-cfg observations=%u chain=20976 switch=1025 labels=406 clobbers=guards=preserved\n", observations);
    return 0;
}
