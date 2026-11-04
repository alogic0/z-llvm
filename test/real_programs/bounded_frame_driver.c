#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern uint64_t bounded_frame_pair(uint64_t, uint64_t, void *);
extern uint64_t bounded_frame_padded_pair(uint64_t, uint64_t, void *);
extern uint64_t bounded_frame_padded_word(uint64_t, uint64_t, void *);
extern uint64_t bounded_frame_call(uint64_t, uint64_t, void *);

__attribute__((noinline))
uint64_t bounded_frame_helper(void *slot, uint64_t a, uint64_t b) {
    if ((uintptr_t)slot & 15) abort();
    uint64_t words[3] = {a + 7, b ^ UINT64_MAX, a ^ b};
    memcpy(slot, words, sizeof(words));
    __asm__ volatile (
        "mov $17, %%rax\n\tmov $19, %%rcx\n\tmov $23, %%rdx\n\t"
        "mov $29, %%rsi\n\tmov $31, %%rdi\n\tmov $37, %%r8\n\t"
        "mov $41, %%r9\n\tmov $43, %%r10\n\tmov $47, %%r11"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc", "memory");
    return ~a + b;
}

int main(void) {
    const uint64_t inputs[] = {0, 1, 127, 128, UINT32_MAX, UINT64_MAX,
                              UINT64_C(1) << 63, UINT64_C(0xdeadbeef01234567)};
    uint64_t (*functions[])(uint64_t, uint64_t, void *) = {
        bounded_frame_pair, bounded_frame_padded_pair,
        bounded_frame_padded_word, bounded_frame_call
    };
    unsigned observations = 0;
    for (unsigned i = 0; i < 8; ++i) for (unsigned j = 0; j < 4; ++j) {
        uint64_t a = inputs[i], b = inputs[(i + 2 * j) % 8];
        for (unsigned f = 0; f < 4; ++f) {
            uint64_t guarded[5];
            memset(guarded, 0xa5, sizeof(guarded));
            uint64_t result = functions[f](a, b, guarded + 1);
            uint64_t expected[3] = {a, b, UINT64_C(0xa5a5a5a5a5a5a5a5)};
            uint64_t answer = a ^ b;
            if (f == 1) {
                expected[2] = UINT64_C(0x0123456789ab0000) | (b & 65535);
                answer ^= UINT64_MAX;
            } else if (f == 2) {
                expected[1] = UINT64_C(0xfedcba9876540000) | (b & 65535);
                answer = a ^ (b & 65535);
            } else if (f == 3) {
                expected[0] = a + 7;
                expected[1] = ~b;
                expected[2] = a ^ b;
                answer = ((a + b) ^ (~a + b)) ^ UINT64_MAX;
            }
            if (result != answer || memcmp(guarded + 1, expected, sizeof(expected)) ||
                guarded[0] != UINT64_C(0xa5a5a5a5a5a5a5a5) ||
                guarded[4] != UINT64_C(0xa5a5a5a5a5a5a5a5)) {
                fprintf(stderr, "bounded-frame mismatch function=%u i=%u j=%u result=%016llx expected=%016llx\n",
                        f, i, j, (unsigned long long)result, (unsigned long long)answer);
                return 1;
            }
            ++observations;
        }
    }
    printf("bounded-frame observations=%u pairs=padding=copies=calls=alignment=live=guards=preserved\n", observations);
    return 0;
}
