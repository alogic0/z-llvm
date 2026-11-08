#include <stdint.h>
#include <stdio.h>

extern uint64_t facts_call(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t facts_stack(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t,
                            uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t facts_phi(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t facts_boolean(uint64_t, uint64_t);
extern uint64_t facts_ignored(uint64_t);
uint64_t facts_recorded;

/* Only the declared low payload satisfies the LLVM facts. All return padding
 * is dirty and every volatile integer register is destroyed. */
#define CLOBBER \
    "xorl %edi,%edi\n" "xorl %esi,%esi\n" "xorl %edx,%edx\n" \
    "xorl %ecx,%ecx\n" "xorl %r8d,%r8d\n" "xorl %r9d,%r9d\n" \
    "xorl %r10d,%r10d\n" "xorl %r11d,%r11d\n"
#define DIRTY(bits) "movabsq $" #bits ",%r10\n" "orq %r10,%rax\n"
__asm__(
    ".text\n"
    ".globl facts_dirty_byte\n.type facts_dirty_byte,@function\n"
    "facts_dirty_byte:\n"
    "movl %edi,%eax\nxorl %esi,%eax\nandl $15,%eax\n"
    DIRTY(0xdeadbeefcafeff00) CLOBBER "ret\n"
    ".size facts_dirty_byte,.-facts_dirty_byte\n"
    ".globl facts_dirty_stack\n.type facts_dirty_stack,@function\n"
    "facts_dirty_stack:\n"
    "movzbl %dil,%eax\nmovzwl %si,%r10d\nxorl %r10d,%eax\n"
    "movzbl %dl,%r10d\nxorl %r10d,%eax\n"
    "movzwl %cx,%r10d\nxorl %r10d,%eax\n"
    "xorl %r8d,%eax\nxorl %r9d,%eax\n"
    "movzbl 8(%rsp),%r10d\nxorl %r10d,%eax\n"
    "movzwl 16(%rsp),%r10d\nxorl %r10d,%eax\nandl $32767,%eax\n"
    DIRTY(0xdeadbeefcafe0000) CLOBBER "ret\n"
    ".size facts_dirty_stack,.-facts_dirty_stack\n"
    ".globl facts_dirty_boolean\n.type facts_dirty_boolean,@function\n"
    "facts_dirty_boolean:\nmovl %edi,%eax\nandl $1,%eax\n"
    DIRTY(0xdeadbeefcafefffe) CLOBBER "ret\n"
    ".size facts_dirty_boolean,.-facts_dirty_boolean\n"
    ".globl facts_dirty_word\n.type facts_dirty_word,@function\n"
    "facts_dirty_word:\nmovzwl %di,%eax\n"
    "movq %rax,facts_recorded(%rip)\nandl $32767,%eax\n"
    DIRTY(0xdeadbeefcafe0000) CLOBBER "ret\n"
    ".size facts_dirty_word,.-facts_dirty_word\n"
);

int main(void) {
    const uint64_t values[] = {0, 1, 15, 128, 65535, 65536, UINT64_MAX,
                               UINT64_C(0xdeadbeefcafe1234)};
    const uint64_t padding[] = {0, UINT64_C(0xdeadbeefcafe0000),
                               UINT64_C(0x123456789abcdef0), UINT64_MAX};
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned a = 0; a < 8; ++a) for (unsigned b = 0; b < 8; ++b)
    for (unsigned p = 0; p < 4; ++p) {
        const uint64_t av = (values[a] & 15) | ((b & 1) ? 240 : 0);
        const uint64_t bv = values[b] & 65535;
        const uint64_t live = values[(a + b) % 8] ^ padding[p];
        const uint64_t ai = (padding[p] & ~UINT64_C(255)) | av;
        const uint64_t bi = (padding[p] & ~UINT64_C(65535)) | bv;
        uint64_t out[3] = {guard, 0, guard};
        uint64_t expected = ((((av ^ bv) & 15) + av) ^ bv) ^ live;
        if ((facts_call(ai, bi, live, &out[1]) & 65535) != (expected & 32767) ||
            out[1] != expected || out[0] != guard || out[2] != guard) return 1;
        ++observations;

        const uint64_t cv = values[(a + 1) % 8] & 255;
        const uint64_t dv = values[(b + 3) % 8] & 32767;
        const uint64_t ev = values[(a + 4) % 8] & UINT32_MAX;
        const uint64_t gv = values[b] & 15;
        const uint64_t hv = values[(a + 5) % 8] & 65535;
        const uint64_t payload = (av ^ bv ^ cv ^ dv ^ ev ^ live ^ gv ^ hv) & 32767;
        out[1] = 0;
        if ((facts_stack(ai, bi, (padding[p] & ~UINT64_C(255)) | cv,
                         (padding[p] & ~UINT64_C(65535)) | dv, ev, live,
                         (padding[p] & ~UINT64_C(255)) | gv,
                         (padding[p] & ~UINT64_C(65535)) | hv, &out[1]) & 65535) != payload ||
            out[1] != (payload ^ live) || out[0] != guard || out[2] != guard) return 2;
        ++observations;

        expected = ((values[a] ^ 1) & 15) ^ live;
        out[1] = 0;
        if ((facts_phi(values[a], b & 1, live, &out[1]) & UINT32_MAX) != (expected & UINT32_MAX) ||
            out[1] != expected || out[0] != guard || out[2] != guard) return 3;
        ++observations;
        if (facts_boolean(values[a], live) != ((values[a] & 1) ? (live ^ 90) : live)) return 4;
        ++observations;
        facts_recorded = guard;
        if (facts_ignored(values[a]) != values[a] || facts_recorded != (values[a] & 65535)) return 5;
        ++observations;
    }
    printf("narrow-abi-facts observations=%u all=match\n", observations);
    return observations == 1280 ? 0 : 6;
}
