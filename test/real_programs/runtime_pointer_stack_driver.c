#include <stdint.h>
#include <stdio.h>

extern uint64_t pointer_stack_roundtrip(void *, uint64_t, void *);
extern uint64_t pointer_stack_pressure(void *, void *, void *, void *, void *, void *);
extern uint64_t pointer_stack_returned(void *, uint64_t, void *);
extern uint64_t pointer_stack_object_address(uint64_t);

__attribute__((noinline)) void pointer_stack_clobber(void) {
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

__attribute__((noinline)) void *pointer_stack_echo(void *pointer) {
    pointer_stack_clobber();
    return pointer;
}

__attribute__((noinline)) uint64_t pointer_stack_read_byte(const unsigned char *pointer) {
    return *pointer;
}

int main(void) {
    unsigned char bytes[64] = {0};
    void *pointers[] = {0, bytes, bytes + 1, bytes + 63};
    uint64_t live[] = {0, 1, 127, 128, UINT32_MAX, UINT64_MAX,
                       UINT64_C(1) << 63, UINT64_C(0xdeadbeef01234567)};
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned p = 0; p < 4; ++p) {
        for (unsigned n = 0; n < 8; ++n) {
            struct { uint64_t before; void *values[5]; uint64_t after; } output =
                {guard, {0}, guard};
            uint64_t expected = (uint64_t)(uintptr_t)pointers[p] ^ live[n];
            if (pointer_stack_roundtrip(pointers[p], live[n], output.values) != expected ||
                output.values[0] != pointers[p] || output.before != guard || output.after != guard)
                return 1;
            ++observations;
            if (pointer_stack_returned(pointers[p], live[n], output.values) != expected ||
                output.values[0] != pointers[p] || output.before != guard || output.after != guard)
                return 2;
            ++observations;
            void *args[5];
            for (unsigned i = 0; i < 5; ++i) args[i] = pointers[(p + n + i) % 4];
            if (pointer_stack_pressure(args[0], args[1], args[2], args[3], args[4], output.values) !=
                (uint64_t)(uintptr_t)args[4] || output.before != guard || output.after != guard)
                return 3;
            for (unsigned i = 0; i < 5; ++i) if (output.values[i] != args[i]) return 4;
            ++observations;
            if (pointer_stack_object_address(live[n]) != (UINT64_C(127) ^ live[n])) return 5;
            ++observations;
        }
    }
    printf("pointer-stack-memory observations=%u pointers=preserved live=preserved guards=preserved\n", observations);
    return 0;
}
