#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef uint64_t (*probe)(uint64_t, uint64_t, void *, uint64_t, const void *);
#define DECLARE(name) extern uint64_t name(uint64_t, uint64_t, void *, uint64_t, const void *)
DECLARE(call_values_undef_i32);
DECLARE(call_values_poison_i64);
DECLARE(call_values_undef_i64);
DECLARE(call_values_poison_ptr);
DECLARE(call_values_undef_ptr);
DECLARE(call_values_init);
DECLARE(call_values_capture);
DECLARE(call_values_is_null);

__attribute__((noinline)) void call_values_clobber(void) {
    __asm__ volatile(
        "movq $101, %%rax\n\t"
        "movq $103, %%rdi\n\t"
        "movq $107, %%rsi\n\t"
        "movq $109, %%rdx\n\t"
        "movq $113, %%rcx\n\t"
        "movq $127, %%r8\n\t"
        "movq $131, %%r9\n\t"
        "movq $137, %%r10\n\t"
        "movq $139, %%r11\n\t"
        : : : "rax", "rdi", "rsi", "rdx", "rcx", "r8", "r9", "r10", "r11", "cc", "memory");
}

static uint64_t mix(uint64_t value) {
    value ^= value >> 30;
    value *= UINT64_C(0xbf58476d1ce4e5b9);
    value ^= value >> 27;
    value *= UINT64_C(0x94d049bb133111eb);
    return value ^ (value >> 31);
}

int main(void) {
    static const probe functions[] = {
        call_values_undef_i32, call_values_poison_i64, call_values_undef_i64,
        call_values_poison_ptr, call_values_undef_ptr, call_values_init,
        call_values_capture, call_values_is_null,
    };
    static const uint64_t edges[] = {0, 1, UINT64_MAX, UINT64_C(0x8000000000000000),
        UINT64_C(0x7fffffffffffffff), UINT64_C(0xffffffff), UINT64_C(0x100000000),
        UINT64_C(0xdeadbeef00000100)};
    uint64_t words[8];
    for (unsigned j = 0; j < 8; ++j) words[j] = mix(j + 5);
    for (unsigned i = 0; i < 512; ++i) {
        const uint64_t a = i < 8 ? edges[i] : mix(i + 91);
        const uint64_t b = mix(i + UINT64_C(0x853a9e1207));
        const uint64_t cookie = mix(i + UINT64_C(0x971fa6309));
        const void *p = i % 3 ? &words[i % 8] : NULL;
        for (unsigned j = 0; j < 8; ++j) {
            _Alignas(16) unsigned char actual[32], expected[32];
            for (unsigned k = 0; k < 32; ++k) actual[k] = (unsigned char)(0xa7 + i + k * 19);
            memcpy(expected, actual, sizeof expected);
            uint64_t answer;
            if (j < 5) {
                const uint64_t sum = a + b;
                const uint64_t salt = j == 0 ? 17 : j < 3 ? 37 : 53;
                memcpy(expected + 8, &sum, sizeof sum);
                answer = (((sum ^ salt) + a) ^ b ^ cookie) ^ (uintptr_t)p;
            } else if (j == 5) {
                const uint16_t small = (uint16_t)(a ^ b);
                memcpy(expected + 12, &small, sizeof small);
                answer = ((uint64_t)small ^ a ^ b ^ cookie) + cookie;
            } else if (j == 6) {
                answer = (uintptr_t)p ^ a ^ b ^ cookie;
            } else {
                answer = (a + b) ^ cookie ^ (uint64_t)(p == NULL);
            }
            const uint64_t result = functions[j](a, b, actual + 8, cookie, p);
            if (result != answer || memcmp(actual, expected, sizeof actual)) {
                fprintf(stderr, "call-values case=%u function=%u result=%" PRIu64 " expected=%" PRIu64 "\n",
                    i, j, result, answer);
                return 10 + (int)j;
            }
        }
    }
    puts("call-values observations=4096 defined-results=live-values=promises=guards=preserved");
    return 0;
}
