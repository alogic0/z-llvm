#include <stdint.h>
#include <stdio.h>

extern uint64_t boolean_call_scalar(uint64_t, uint64_t, uint64_t *);
extern uint64_t boolean_call_branch(uint64_t, uint64_t, uint64_t *);
extern uint64_t boolean_call_stack_pointer(uint64_t, uint64_t, uint64_t *);
extern uint64_t boolean_call_live_return(uint64_t, uint64_t, uint64_t *);

/* AL is 0 or 1; every other RAX bit and all volatile integer argument homes
 * are deliberately unreliable. These callees obey the preserved-register ABI. */
#define CLOBBER_VOLATILE_ARGS \
    "xorl %edi,%edi\n" "xorl %esi,%esi\n" "xorl %edx,%edx\n" \
    "xorl %ecx,%ecx\n" "xorl %r8d,%r8d\n" "xorl %r9d,%r9d\n" \
    "xorl %r10d,%r10d\n" "xorl %r11d,%r11d\n"
__asm__(
    ".text\n"
    ".globl bool_return_dirty\n"
    ".type bool_return_dirty,@function\n"
    "bool_return_dirty:\n"
    "movq %rdi,%rax\n"
    "andl $1,%eax\n"
    "movabsq $0xdeadbeefcafe0000,%r10\n"
    "orq %r10,%rax\n"
    CLOBBER_VOLATILE_ARGS
    "ret\n"
    ".size bool_return_dirty,.-bool_return_dirty\n"
    ".globl bool_return_dirty_ptr\n"
    ".type bool_return_dirty_ptr,@function\n"
    "bool_return_dirty_ptr:\n"
    "movq (%rdi),%rdi\n"
    "jmp bool_return_dirty\n"
    ".size bool_return_dirty_ptr,.-bool_return_dirty_ptr\n"
    ".globl bool_return_seed\n"
    ".type bool_return_seed,@function\n"
    "bool_return_seed:\n"
    "movq %rdi,%rax\n"
    "movabsq $0x123456789abcdef0,%r10\n"
    "xorq %r10,%rax\n"
    CLOBBER_VOLATILE_ARGS
    "ret\n"
    ".size bool_return_seed,.-bool_return_seed\n"
);

int main(void) {
    const uint64_t values[] = {
        0, 1, 2, 3, 127, 128, UINT64_MAX, UINT64_C(0x8000000000000000)
    };
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    uint64_t (*const functions[])(uint64_t, uint64_t, uint64_t *) = {
        boolean_call_scalar, boolean_call_branch,
        boolean_call_stack_pointer, boolean_call_live_return
    };
    unsigned observations = 0;
    for (unsigned b = 0; b < 8; ++b) {
        for (unsigned l = 0; l < 8; ++l) {
            const uint64_t bit = values[b] & 1;
            const uint64_t expected[] = {
                bit ^ values[l], values[l] ^ (bit ? 170 : 85),
                bit ^ values[l], UINT64_C(0x123456789abcdef0) ^ bit
            };
            for (unsigned f = 0; f < 4; ++f) {
                uint64_t output[3] = { guard, UINT64_MAX, guard };
                const uint64_t actual = functions[f](values[b], values[l], &output[1]);
                if (actual != expected[f] || output[1] != bit ||
                    output[0] != guard || output[2] != guard) {
                    fprintf(stderr, "boolean call mismatch function=%u input=%u live=%u\n", f, b, l);
                    return 1;
                }
                ++observations;
            }
        }
    }
    printf("boolean-call-returns observations=%u scalar=branch=stack=live=guards=preserved\n", observations);
    return 0;
}
