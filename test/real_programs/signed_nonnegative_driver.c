#include <stdint.h>
#include <stdio.h>

extern uint64_t nonnegative_i32(int32_t, uint64_t, void *);
extern uint64_t nonnegative_i64(int64_t, uint64_t, void *);
extern uint64_t nonnegative_returned(int32_t, uint64_t, void *);
extern uint64_t nonnegative_spilled(int32_t, int32_t, int32_t, int32_t, int32_t, void *);

__attribute__((noinline)) void signed_nonnegative_clobber(void) {
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

__attribute__((noinline)) int32_t signed_nonnegative_echo(int32_t value) {
    signed_nonnegative_clobber();
    return value;
}

int main(void) {
    const int32_t values32[] = {INT32_MIN, -65537, -1, 0, 1, 65535, INT32_MAX, INT32_MIN + 1};
    const int64_t values64[] = {INT64_MIN, -INT64_C(4294967296), -1, 0, 1, INT32_MAX,
                               INT64_C(4294967296), INT64_MAX};
    const uint64_t lives[] = {0, 1, 127, 128, UINT32_MAX, UINT64_C(1) << 63,
                             UINT64_MAX, UINT64_C(0xdeadbeef01234567)};
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned v = 0; v < 8; ++v) {
        for (unsigned l = 0; l < 8; ++l) {
            struct { uint64_t before, values[5], after; } output = {guard, {0}, guard};
            uint64_t truth32 = values32[v] >= 0;
            uint64_t truth64 = values64[v] >= 0;
            if (nonnegative_i32(values32[v], lives[l], output.values) != (truth32 ^ lives[l]) ||
                output.values[0] != truth32) return 1;
            ++observations;
            if (nonnegative_i64(values64[v], lives[l], output.values) != (truth64 ^ lives[l]) ||
                output.values[0] != truth64) return 2;
            ++observations;
            if (nonnegative_returned(values32[v], lives[l], output.values) != (truth32 ^ lives[l]) ||
                output.values[0] != truth32) return 3;
            ++observations;
            int32_t args[5];
            for (unsigned i = 0; i < 5; ++i) args[i] = values32[(v + l + i) % 8];
            if (nonnegative_spilled(args[0], args[1], args[2], args[3], args[4], output.values) !=
                (uint64_t)(args[4] >= 0)) return 4;
            for (unsigned i = 0; i < 5; ++i) if (output.values[i] != (uint64_t)(args[i] >= 0)) return 5;
            ++observations;
            if (output.before != guard || output.after != guard) return 6;
        }
    }
    printf("signed-nonnegative observations=%u signed=preserved live=preserved guards=preserved\n", observations);
    return 0;
}
