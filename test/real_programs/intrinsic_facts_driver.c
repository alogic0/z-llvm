#include <stdint.h>
#include <stdio.h>

typedef uint64_t (*operation)(uint64_t, uint64_t, uint64_t *, uint64_t);
extern uint64_t intrinsic_facts_add(uint64_t, uint64_t, uint64_t *, uint64_t);
extern uint64_t intrinsic_facts_wrapped(uint64_t, uint64_t, uint64_t *, uint64_t);
extern uint64_t intrinsic_facts_sub(uint64_t, uint64_t, uint64_t *, uint64_t);
extern uint64_t intrinsic_facts_add23(uint64_t, uint64_t, uint64_t *, uint64_t);
extern uint64_t intrinsic_facts_min6(uint64_t, uint64_t, uint64_t *, uint64_t);
extern uint64_t intrinsic_facts_reverse23(uint64_t, uint64_t, uint64_t *, uint64_t);

__asm__(
    ".text\n.globl intrinsic_facts_clobber\n.type intrinsic_facts_clobber,@function\n"
    "intrinsic_facts_clobber:\n"
    "xorl %eax,%eax\nxorl %edi,%edi\nxorl %esi,%esi\nxorl %edx,%edx\n"
    "xorl %ecx,%ecx\nxorl %r8d,%r8d\nxorl %r9d,%r9d\nxorl %r10d,%r10d\nxorl %r11d,%r11d\nret\n"
    ".size intrinsic_facts_clobber,.-intrinsic_facts_clobber\n"
);

static uint64_t saturated_add(uint64_t a, uint64_t b) {
    return UINT64_MAX - a < b ? UINT64_MAX : a + b;
}

int main(void) {
    const uint64_t values[] = {0, 1, 2, 15, 16, 31, 32, 127, 128, 4194303, 8388607,
                               UINT32_MAX, UINT64_C(1) << 63, UINT64_MAX - 1,
                               UINT64_MAX, UINT64_C(0xdeadbeef01234567)};
    const operation operations[] = {intrinsic_facts_add, intrinsic_facts_wrapped,
        intrinsic_facts_sub, intrinsic_facts_add23, intrinsic_facts_min6, intrinsic_facts_reverse23};
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned i = 0; i < 16; ++i) for (unsigned j = 0; j < 16; ++j) {
        uint64_t a = values[i], b = values[j], salt = a * 37 + b * 19;
        uint64_t sum23 = ((a & 8388607) | 1) + (b & 8388607);
        uint64_t reverse = 0;
        for (unsigned bit = 0; bit < 23; ++bit) reverse |= ((a & 4194303) >> bit & 1) << (22 - bit);
        const uint64_t expected[] = {saturated_add(a, b), saturated_add(a | 32, b | 1),
            a < (b | 1) ? 0 : a - (b | 1), sum23 > 8388607 ? 8388607 : sum23,
            (a & 15) < (b & 15) ? (a & 15) : (b & 15), reverse};
        for (unsigned op = 0; op < 6; ++op) {
            uint64_t out[] = {guard, ~expected[op], guard};
            if (operations[op](a, b, &out[1], salt) != (a ^ b ^ salt) || out[1] != expected[op] ||
                out[0] != guard || out[2] != guard) return (int)op + 1;
            ++observations;
        }
    }
    printf("intrinsic-facts observations=%u ranges=saturation=permutation=live=guards=preserved\n", observations);
    return observations == 1536 ? 0 : 7;
}
