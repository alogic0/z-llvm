#include <stdint.h>
#include <stdio.h>

#define DECLARE(name) extern uint64_t name(void *, uint64_t, uint64_t, void **, uint64_t)
DECLARE(general_stride_56);
DECLARE(general_stride_padding);
DECLARE(general_stride_nested);
DECLARE(general_stride_called);
DECLARE(general_stride_store);

typedef uint64_t (*Probe)(void *, uint64_t, uint64_t, void **, uint64_t);

__attribute__((noinline)) uint64_t general_stride_helper(uint64_t index) {
    __asm__ volatile (
        "mov $17, %%rax\n\tmov $19, %%rcx\n\tmov $23, %%rdx\n\t"
        "mov $29, %%rsi\n\tmov $31, %%rdi\n\tmov $37, %%r8\n\t"
        "mov $41, %%r9\n\tmov $43, %%r10\n\tmov $47, %%r11"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc", "memory");
    return index;
}

int main(void) {
    uint64_t anchor = 0;
    const uint64_t bases[] = {0, 1, 4096, UINT64_MAX, UINT64_MAX - 7,
        UINT64_C(0x8000000000000000), UINT64_C(0x7fff00000000), (uintptr_t)&anchor};
    const uint64_t indexes[] = {0, 1, 2, 7, UINT64_MAX, UINT64_MAX - 1,
        UINT64_C(0x8000000000000000), UINT64_C(0x2000000000000001)};
    const Probe functions[] = {general_stride_56, general_stride_padding,
        general_stride_nested, general_stride_called};
    const uint64_t strides[] = {56, 12, 15, 255};
    const uintptr_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned b = 0; b < 8; ++b) for (unsigned i = 0; i < 8; ++i) {
        const uint64_t live = UINT64_C(0x123456789abcdef0) ^ indexes[i];
        const uint64_t salt = UINT64_C(0xfedcba9876543210) ^ bases[b];
        for (unsigned f = 0; f < 4; ++f) {
            void *output[] = {(void *)guard, NULL, (void *)guard};
            /* Synthetic pointers are only computed, never dereferenced. */
            const uint64_t address = bases[b] + indexes[i] * strides[f];
            const uint64_t expected = address ^ bases[b] ^ indexes[i] ^ live ^ salt;
            const uint64_t actual = functions[f]((void *)(uintptr_t)bases[b], indexes[i], live, &output[1], salt);
            if ((uintptr_t)output[1] != address || actual != expected ||
                (uintptr_t)output[0] != guard || (uintptr_t)output[2] != guard) {
                fprintf(stderr, "general stride mismatch function=%u base=%u index=%u\n", f, b, i);
                return 1;
            }
            ++observations;
        }
        /* This population dereferences real storage at positive/negative
         * 56-byte offsets, and checks every untouched word and both guards. */
        uint64_t storage[65];
        for (unsigned n = 0; n < 65; ++n) storage[n] = guard ^ n;
        uint64_t *base = storage + 29;
        const int64_t index = (int64_t)i - 3;
        const unsigned destination = (unsigned)(29 + index * 7);
        const uint64_t value = bases[b];
        void *output[] = {(void *)guard, NULL, (void *)guard};
        const uintptr_t address = (uintptr_t)&storage[destination];
        const uint64_t expected = address ^ (uintptr_t)base ^ (uint64_t)index ^ value ^ salt;
        if (general_stride_store(base, (uint64_t)index, value, &output[1], salt) != expected ||
            (uintptr_t)output[1] != address || (uintptr_t)output[0] != guard || (uintptr_t)output[2] != guard)
            return 2;
        for (unsigned n = 0; n < 65; ++n) if (storage[n] != (n == destination ? value : guard ^ n)) {
            fprintf(stderr, "general stride store mismatch base=%u index=%u word=%u\n", b, i, n);
            return 3;
        }
        ++observations;
    }
    printf("general-array-stride observations=%u padding=nested=negative=wrap=calls=live=stores=guards=preserved\n", observations);
    return 0;
}
