#include <stdint.h>
#include <stdio.h>

typedef uint64_t (*freeze_fn)(const uint64_t *, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t pointer_freeze_arg(const uint64_t *, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t pointer_freeze_gep(const uint64_t *, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t pointer_freeze_phi(const uint64_t *, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t pointer_freeze_calls(const uint64_t *, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t pointer_freeze_stack(const uint64_t *, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t pointer_freeze_array(const uint64_t *, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t pointer_freeze_readonly(const uint64_t *, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);

__attribute__((noinline)) uint64_t pointer_freeze_clobber(uint64_t value) {
    uint64_t result = value ^ UINT64_C(0xfeedface87654321);
    __asm__ volatile("" : "+a"(result) : : "rdi", "rsi", "rdx", "rcx", "r8", "r9", "r10", "r11", "memory", "cc");
    return result;
}

int main(void) {
    const uint64_t values[] = {0, 1, 2, 7, 8, 255, 256, 65535, 65536, UINT32_MAX,
        UINT64_C(0x100000000), UINT64_C(0x7fffffffffffffff), UINT64_C(0x8000000000000000),
        UINT64_C(0xfedcba9876543210), UINT64_MAX - 1, UINT64_MAX};
    const freeze_fn functions[] = {pointer_freeze_arg, pointer_freeze_gep, pointer_freeze_phi,
        pointer_freeze_calls, pointer_freeze_stack, pointer_freeze_array, pointer_freeze_readonly};
    unsigned observations = 0;
    for (unsigned i = 0; i < 16; ++i) for (unsigned j = 0; j < 16; ++j) {
        uint64_t words[8];
        for (unsigned k = 0; k < 8; ++k) words[k] = values[j] ^ (UINT64_C(0x123456789abcdef) * (k + 1));
        uint64_t index = values[i], b = values[j], c = values[(i + j + 3) % 16], d = values[(j + 5) % 16];
        for (unsigned f = 0; f < 7; ++f) {
            uint64_t expected;
            switch (f) {
            case 0: expected = words[0] ^ b; break;
            case 1: expected = words[index & 7] ^ b; break;
            case 2: expected = words[(index & 1) ? index & 7 : 0] ^ b; break;
            case 3: expected = words[index & 7] ^ b ^ c; break;
            case 4: expected = b ^ c ^ d; break;
            case 5: expected = (uint32_t)b ^ c; break;
            default: expected = (7 + 12 * (index & 127)) ^ b; break;
            }
            uint64_t guarded[] = {UINT64_C(0x123456789abcdef0), 0, 0, UINT64_C(0xfedcba9876543210)};
            uint64_t actual = functions[f](words, index, b, c, d, &guarded[1]);
            if (actual != expected || guarded[1] != (uintptr_t)words || guarded[2] != (index ^ b ^ c ^ d) ||
                guarded[0] != UINT64_C(0x123456789abcdef0) || guarded[3] != UINT64_C(0xfedcba9876543210)) {
                fprintf(stderr, "pointer freeze mismatch function=%u i=%u j=%u\n", f, i, j);
                return 1 + f;
            }
            ++observations;
        }
    }
    printf("pointer-freeze observations=%u pointers=aliases=phis=calls=stack=readonly=guards=preserved\n", observations);
    return 0;
}
