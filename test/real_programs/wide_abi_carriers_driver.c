#include <stdint.h>
#include <stdio.h>

extern uint64_t wide_abi_entry33(uint64_t, uint64_t *, uint64_t);
extern uint64_t wide_abi_call49(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t wide_abi_call33(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t wide_abi_stack37(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t,
                                uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t wide_abi_phi37(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t wide_abi_range63(uint64_t, uint64_t, uint64_t *);

/* Interpret only each declared payload width; LLVM may leave padding dirty.
 * Return padding is deliberately dirty and all volatile GPRs are destroyed. */
#define CLOBBER \
    "xorl %edi,%edi\nxorl %esi,%esi\nxorl %edx,%edx\nxorl %ecx,%ecx\n" \
    "xorl %r8d,%r8d\nxorl %r9d,%r9d\nxorl %r10d,%r10d\nxorl %r11d,%r11d\n"
#define FINISH(mask, padding) \
    "movabsq $" #mask ",%r10\nandq %r10,%rax\n" \
    "movabsq $" #padding ",%r10\norq %r10,%rax\n" CLOBBER "ret\n"
#define FIRST_TWO \
    "movq %rdi,%rax\nmovabsq $0x1ffffffff,%r10\nandq %r10,%rax\n" \
    "movabsq $0x1fffffffff,%r10\nandq %r10,%rsi\nxorq %rsi,%rax\n"
__asm__(
    ".text\n.globl wide_dirty33\n.type wide_dirty33,@function\nwide_dirty33:\n"
    FIRST_TWO FINISH(0x1ffffffff, 0xfffffffe00000000)
    ".size wide_dirty33,.-wide_dirty33\n"
    ".globl wide_dirty37\n.type wide_dirty37,@function\nwide_dirty37:\n"
    "movq %rdi,%rax\nxorq $17,%rax\n" FINISH(0x1fffffffff, 0xffffffe000000000)
    ".size wide_dirty37,.-wide_dirty37\n"
    ".globl wide_dirty49\n.type wide_dirty49,@function\nwide_dirty49:\n"
    FIRST_TWO "xorq %rdx,%rax\nxorq %rcx,%rax\n" FINISH(0x1ffffffffffff, 0xfffe000000000000)
    ".size wide_dirty49,.-wide_dirty49\n"
    ".globl wide_dirty_stack\n.type wide_dirty_stack,@function\nwide_dirty_stack:\n"
    FIRST_TWO "xorq %rdx,%rax\nxorq %rcx,%rax\nmovzbl %r8b,%r10d\nxorq %r10,%rax\n"
    "xorq %r9,%rax\nxorq 8(%rsp),%rax\nmovq 16(%rsp),%r11\n"
    "movabsq $0x1fffffffff,%r10\nandq %r10,%r11\nxorq %r11,%rax\n"
    FINISH(0x1ffffffffffff, 0xfffe000000000000)
    ".size wide_dirty_stack,.-wide_dirty_stack\n"
    ".globl wide_dirty63\n.type wide_dirty63,@function\nwide_dirty63:\n"
    "movq %rdi,%rax\nandq $15,%rax\n" FINISH(0x7fffffffffffffff, 0x8000000000000000)
    ".size wide_dirty63,.-wide_dirty63\n"
);

static uint64_t padded(uint64_t value, uint64_t mask, uint64_t padding) {
    return (value & mask) | (padding & ~mask);
}

int main(void) {
    const uint64_t m33 = (UINT64_C(1) << 33) - 1, m37 = (UINT64_C(1) << 37) - 1;
    const uint64_t m49 = (UINT64_C(1) << 49) - 1, m63 = (UINT64_C(1) << 63) - 1;
    const uint64_t values[] = {0, 1, UINT32_MAX, UINT64_C(1) << 33, UINT64_C(1) << 37,
                               UINT64_C(1) << 49, UINT64_MAX, UINT64_C(0xdeadbeefcafe1234)};
    const uint64_t padding[] = {0, UINT64_C(0xdeadbeefcafe0000), UINT64_C(0x123456789abcdef0), UINT64_MAX};
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned a = 0; a < 8; ++a) for (unsigned b = 0; b < 8; ++b)
    for (unsigned p = 0; p < 4; ++p) {
        uint64_t av = values[a] & m33, bv = values[b] & m37;
        uint64_t cv = values[(a + 3) % 8] & m49, dv = values[(b + 5) % 8] & m63;
        uint64_t live = values[(a + b) % 8] ^ padding[p];
        uint64_t ai = padded(av, m33, padding[p]), bi = padded(bv, m37, padding[p]);
        uint64_t ci = padded(cv, m49, padding[p]), di = padded(dv, m63, padding[p]);
        uint64_t out[] = {guard, 0, guard};
        if ((wide_abi_entry33(ai, &out[1], live) & m33) != av || out[1] != (av ^ live)) return 1;
        ++observations;
        uint64_t result = (av ^ bv ^ cv ^ dv) & m49;
        if ((wide_abi_call49(ai, bi, ci, di, live, &out[1]) & m49) != result ||
            out[1] != (result ^ av ^ bv ^ cv ^ dv ^ live)) return 2;
        ++observations;
        result = av ^ m33;
        if ((wide_abi_call33(ai, bi, ci, di, live, &out[1]) & m33) != result ||
            out[1] != (result ^ av ^ bv ^ cv ^ dv ^ live)) return 3;
        ++observations;
        uint64_t ev = values[(a + 1) % 8] & 255, gv = values[(b + 1) % 8] & m49;
        uint64_t hv = values[(a + b + 2) % 8] & m37;
        result = (av ^ bv ^ cv ^ dv ^ ev ^ live ^ gv ^ hv) & m49;
        if ((wide_abi_stack37(ai, bi, ci, di, padded(ev, 255, padding[p]), live,
                              padded(gv, m49, padding[p]), padded(hv, m37, padding[p]), &out[1]) & m37) != (result & m37) ||
            out[1] != (result ^ live)) return 4;
        ++observations;
        result = (((b & 1) ? cv : dv) ^ 17) & m37;
        if ((wide_abi_phi37(ci, di, b & 1, live, &out[1]) & m37) != result ||
            out[1] != (result ^ cv ^ dv ^ live)) return 5;
        ++observations;
        uint64_t ranged = (values[a] & 15) | ((b & 1) ? (m63 & ~UINT64_C(15)) : 0);
        result = ranged & 15;
        if ((wide_abi_range63(padded(ranged, m63, padding[p]), live, &out[1]) & m63) != result ||
            out[1] != (result ^ ranged ^ live)) return 6;
        ++observations;
        if (out[0] != guard || out[2] != guard) return 7;
    }
    printf("wide-abi-carriers observations=%u bits=33,37,49,63 padding=stack=phi=live=guards=preserved\n", observations);
    return observations == 1536 ? 0 : 8;
}
