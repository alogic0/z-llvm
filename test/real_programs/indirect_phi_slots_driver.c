#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define DECLARE(N) extern uint64_t indirect_phi_integer_##N(uint64_t,uint64_t,uint64_t,void *);
DECLARE(1) DECLARE(2) DECLARE(8) DECLARE(16) DECLARE(24) DECLARE(32)
DECLARE(40) DECLARE(56) DECLARE(64) DECLARE(65) DECLARE(96) DECLARE(128)
extern uint64_t indirect_phi_floating_16(uint64_t,uint64_t,uint64_t,void *);
extern uint64_t indirect_phi_floating_32(uint64_t,uint64_t,uint64_t,void *);
extern uint64_t indirect_phi_floating_64(uint64_t,uint64_t,uint64_t,void *);
extern uint64_t indirect_phi_pointer_64(uint64_t,void *,void *,void *,uint64_t);
extern uint64_t indirect_phi_inactive_poison(uint64_t,uint64_t,uint64_t,void *);
static uint64_t noise(uint64_t x) { return x * UINT64_C(0x9e3779b97f4a7c15) + 1; }
#define CLOBBER() __asm__ volatile("mov $17, %%rax; mov $23, %%rcx; mov $31, %%rdx; mov $43, %%rsi; mov $59, %%rdi; mov $61, %%r8; mov $71, %%r9; mov $83, %%r10; mov $97, %%r11; pxor %%xmm0, %%xmm0" ::: "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "xmm0", "memory", "cc")
__attribute__((noinline)) uint64_t indirect_phi_noise(uint64_t value) { const uint64_t result = noise(value); CLOBBER(); return result; }
__attribute__((noinline)) void *indirect_phi_target(void *value) { void *result = value; CLOBBER(); return result; }
typedef uint64_t (*Function)(uint64_t,uint64_t,uint64_t,void *);
static uint64_t fold(unsigned __int128 x) { return (uint64_t)x ^ (uint64_t)(x >> 64); }
static int check_bytes(const unsigned char *output, unsigned width, unsigned __int128 x, unsigned __int128 y) {
    unsigned char expected[64]; memset(expected, 0xa5, sizeof expected);
    unsigned char defined[64]; memset(defined, 255, sizeof defined);
    const unsigned bytes = (width + 7) / 8;
    for (unsigned j = 0; j < bytes; ++j) { expected[16+j] = x >> (8*j); expected[32+j] = y >> (8*j); }
    if (width % 8) defined[16+bytes-1] = defined[32+bytes-1] = (1u << (width % 8)) - 1;
    for (unsigned j = 0; j < sizeof expected; ++j) if ((output[j] & defined[j]) != (expected[j] & defined[j])) return 1;
    return 0;
}
int main(void) {
    const Function functions[] = {indirect_phi_integer_1, indirect_phi_integer_2, indirect_phi_integer_8, indirect_phi_integer_16,
        indirect_phi_integer_24, indirect_phi_integer_32, indirect_phi_integer_40, indirect_phi_integer_56, indirect_phi_integer_64,
        indirect_phi_integer_65, indirect_phi_integer_96, indirect_phi_integer_128,
        indirect_phi_floating_16, indirect_phi_floating_32, indirect_phi_floating_64};
    const unsigned widths[] = {1,2,8,16,24,32,40,56,64,65,96,128,16,32,64};
    unsigned observations = 0;
    uint64_t seed = UINT64_C(0xa510c72e83b946df);
    for (unsigned i = 0; i < 128; ++i) {
        seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17;
        const uint64_t alt = seed ^ UINT64_C(0xf36a09d8e1257c43), count = i % 33;
        const uint64_t last = count ? noise(count - 1) : seed;
        for (unsigned f = 0; f < sizeof functions / sizeof functions[0]; ++f) {
            const unsigned width = widths[f];
            const unsigned __int128 mask = width == 128 ? ~(unsigned __int128)0 : ((unsigned __int128)1 << width) - 1;
            unsigned __int128 a = width > 64 ? (((unsigned __int128)alt << 64) | seed) & mask : seed & mask;
            unsigned __int128 b = width > 64 ? ~a & mask : alt & mask;
            unsigned __int128 x = count & 1 ? b : a, y = count & 1 ? a : b;
            unsigned char output[64]; memset(output, 0xa5, sizeof output);
            uint64_t actual = functions[f](count, seed, alt, output + 16), expected = fold(x) ^ fold(y) ^ last ^ seed;
            if (actual != expected || check_bytes(output, width, x, y)) {
                fprintf(stderr, "indirect-phi case=%u f=%u width=%u count=%llu actual=%llx expected=%llx bytes=%d\n", i, f, width, (unsigned long long)count, (unsigned long long)actual, (unsigned long long)expected, check_bytes(output, width, x, y));
                return 1 + f;
            }
            ++observations;
        }
        uint64_t first = seed ^ 17, second = alt ^ 29;
        unsigned char output[64]; memset(output, 0xa5, sizeof output);
        const uintptr_t x = (uintptr_t)((count & 1) ? &second : &first), y = (uintptr_t)((count & 1) ? &first : &second);
        const uint64_t actual = indirect_phi_pointer_64(count, &first, &second, output + 16, seed), expected = first ^ second ^ last ^ seed;
        if (actual != expected || check_bytes(output, 64, x, y) || first != (seed ^ 17) || second != (alt ^ 29)) return 30;
        ++observations;
        const uint64_t key = i & 1, poison_seed = key ? seed == UINT64_MAX ? 1 : seed : UINT64_MAX;
        const uint64_t poison_expected = poison_seed + key;
        memset(output, 0xa5, sizeof output);
        const uint64_t poison_actual = indirect_phi_inactive_poison(key, poison_seed, alt, output + 16);
        if (poison_actual != poison_expected || check_bytes(output, 64, poison_expected, UINT64_C(0xa5a5a5a5a5a5a5a5))) return 31;
        ++observations;
    }
    printf("indirect-phi-slots observations=%u targets=parallel=poison=clobbers=guards=preserved\n", observations);
    return 0;
}
