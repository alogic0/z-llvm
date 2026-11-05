#include <stdint.h>
#include <stdio.h>

#define DECLARE(name) extern uint64_t name(void *, uint64_t, uint64_t, uint64_t, uint64_t *)
DECLARE(remainder_u8);
DECLARE(remainder_u16);
DECLARE(remainder_u32);
DECLARE(remainder_u64);
DECLARE(remainder_signed_spelling);
DECLARE(remainder_one);
DECLARE(remainder_page);
DECLARE(remainder_word);
typedef uint64_t (*Probe)(void *, uint64_t, uint64_t, uint64_t, uint64_t *);

__attribute__((noinline)) void remainder_touch(volatile uint64_t *slot) {
    *slot = *slot;
    __asm__ volatile (
        "mov $17, %%rax\n\tmov $19, %%rcx\n\tmov $23, %%rdx\n\t"
        "mov $29, %%rsi\n\tmov $31, %%rdi\n\tmov $37, %%r8\n\t"
        "mov $41, %%r9\n\tmov $43, %%r10\n\tmov $47, %%r11"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc", "memory");
}

int main(void) {
    const uint64_t values[] = {0, 1, 4095, 4096, 4097, UINT64_C(0x8000000000000000),
        UINT64_C(0x123456789abcdef0), UINT64_MAX};
    const uint64_t takes[] = {0, 1, 2, 7, UINT64_MAX, UINT64_C(0x8000000000000000),
        UINT64_C(0x123456789abcdef0), UINT64_C(0x2000000000000001)};
    const Probe functions[] = {remainder_u8, remainder_u16, remainder_u32, remainder_u64, remainder_signed_spelling, remainder_one, remainder_page, remainder_word};
    const unsigned widths[] = {8, 16, 32, 64, 64, 64, 64, 64};
    const uint64_t divisors[] = {128, 32768, UINT64_C(2147483648), UINT64_C(9223372036854775808),
        UINT64_C(9223372036854775808), 1, 4096, UINT64_C(4294967296)};
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned v = 0; v < 8; ++v) for (unsigned t = 0; t < 8; ++t) {
        for (unsigned f = 0; f < 8; ++f) {
            uint64_t input = values[v];
            const uint64_t mask = widths[f] == 64 ? UINT64_MAX : (UINT64_C(1) << widths[f]) - 1;
            const uint64_t original = takes[t] ? input & mask : 0;
            const uint64_t expected = original % divisors[f];
            const uint64_t left = UINT64_C(0x9876543210fedcba) + v * 17;
            const uint64_t right = UINT64_C(0x0123456789abcdef) ^ (t * 257);
            uint64_t output[] = {guard, ~expected, guard};
            const uint64_t actual = functions[f](takes[t] ? &input : NULL, takes[t], left, right, &output[1]);
            if (actual != (expected ^ original ^ left ^ right ^ takes[t]) || output[1] != expected ||
                output[0] != guard || output[2] != guard || input != values[v]) {
                fprintf(stderr, "constant remainder mismatch function=%u value=%u take=%u\n", f, v, t);
                return 1;
            }
            ++observations;
        }
    }
    printf("constant-remainder observations=%u widths=high-bit=one=branches=calls=live=guards=preserved\n", observations);
    return 0;
}
