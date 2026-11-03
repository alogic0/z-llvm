#include <stdint.h>
#include <stdio.h>

extern uint64_t integer_pointer_roundtrip(uint64_t, uint64_t, void *);
extern uint64_t integer_pointer_spilled(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, void *);
extern uint64_t integer_pointer_returned(uint64_t, uint64_t, void *);
extern void *integer_pointer_identity(uint64_t);

__attribute__((noinline)) void integer_pointer_clobber(void) {
    __asm__ volatile("xor %%eax, %%eax\n\t"
                     "xor %%edi, %%edi\n\t"
                     "xor %%esi, %%esi\n\t"
                     "xor %%edx, %%edx\n\t"
                     "xor %%ecx, %%ecx\n\t"
                     "xor %%r8d, %%r8d\n\t"
                     "xor %%r9d, %%r9d\n\t"
                     "xor %%r10d, %%r10d\n\t"
                     "xor %%r11d, %%r11d"
                     ::: "rax", "rdi", "rsi", "rdx", "rcx", "r8", "r9", "r10", "r11", "cc", "memory");
}

__attribute__((noinline)) uint64_t integer_pointer_echo(uint64_t value) {
    integer_pointer_clobber();
    return value;
}

int main(void) {
    const uint64_t values[] = {0, 1, UINT64_C(2147483648), UINT32_MAX,
        UINT64_C(4294967296), UINT64_C(1) << 63, UINT64_MAX,
        UINT64_C(0xdeadbeef01234567)};
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned v = 0; v < 8; ++v) {
        for (unsigned l = 0; l < 8; ++l) {
            struct { uint64_t before; void *pointers[5]; uint64_t after; } output = {guard, {0}, guard};
            if (integer_pointer_roundtrip(values[v], values[l], output.pointers) !=
                ((values[v] + values[v]) ^ values[l]) || (uint64_t)(uintptr_t)output.pointers[0] != values[v]) return 1;
            ++observations;
            if (integer_pointer_returned(values[v], values[l], output.pointers) != (values[v] ^ values[l]) ||
                (uint64_t)(uintptr_t)output.pointers[0] != values[v] ||
                (uint64_t)(uintptr_t)output.pointers[1] != values[l]) return 2;
            ++observations;
            uint64_t args[5];
            for (unsigned i = 0; i < 5; ++i) args[i] = values[(v + l + i) % 8];
            if (integer_pointer_spilled(args[0], args[1], args[2], args[3], args[4], output.pointers) !=
                (args[0] ^ args[4])) return 3;
            for (unsigned i = 0; i < 5; ++i) if ((uint64_t)(uintptr_t)output.pointers[i] != args[i]) return 4;
            ++observations;
            if ((uint64_t)(uintptr_t)integer_pointer_identity(values[v]) != values[v]) return 5;
            ++observations;
            if (output.before != guard || output.after != guard) return 6;
        }
    }
    printf("integer-pointer-casts observations=%u bits=preserved live=preserved guards=preserved\n", observations);
    return 0;
}
