#include <stdint.h>
#include <stdio.h>

#define DECLARE_WIDTH(n) \
    extern uint64_t narrow_entry_##n(uint64_t, uint64_t, uint64_t *); \
    extern uint64_t narrow_return_##n(uint64_t, uint64_t, uint64_t *)
DECLARE_WIDTH(1);
DECLARE_WIDTH(3);
DECLARE_WIDTH(8);
DECLARE_WIDTH(16);
extern uint64_t narrow_call_3(uint64_t, uint64_t, uint64_t *);
extern uint64_t narrow_call_8(uint64_t, uint64_t, uint64_t *);
extern uint64_t narrow_call_16(uint64_t, uint64_t, uint64_t *);
extern uint64_t narrow_constants(uint64_t, uint64_t, uint64_t *);
extern void narrow_last_use(uint64_t);
uint64_t narrow_recorded;

/* Assembly supplies and observes the low register payload directly. It makes
 * every volatile register unreliable, including return padding. */
#define CLOBBER \
    "xorl %edi,%edi\n" "xorl %esi,%esi\n" "xorl %edx,%edx\n" \
    "xorl %ecx,%ecx\n" "xorl %r8d,%r8d\n" "xorl %r9d,%r9d\n" \
    "xorl %r10d,%r10d\n" "xorl %r11d,%r11d\n"
#define DIRTY_HELPER(n, mask, padding) \
    ".globl narrow_dirty_" #n "\n" \
    ".type narrow_dirty_" #n ",@function\n" \
    "narrow_dirty_" #n ":\n" \
    "movl %edi,%eax\n" "xorl $90,%eax\n" "andl $" #mask ",%eax\n" \
    "movabsq $" #padding ",%r10\n" "orq %r10,%rax\n" \
    CLOBBER "ret\n" \
    ".size narrow_dirty_" #n ",.-narrow_dirty_" #n "\n"
__asm__(
    ".text\n"
    DIRTY_HELPER(3, 7, 0xdeadbeefcafefff8)
    DIRTY_HELPER(8, 255, 0xdeadbeefcafeff00)
    DIRTY_HELPER(16, 65535, 0xdeadbeefcafe0000)
    ".globl narrow_dirty_constants\n"
    ".type narrow_dirty_constants,@function\n"
    "narrow_dirty_constants:\n"
    "movl %edi,%eax\n" "andl $7,%eax\n"
    "andl $255,%esi\n" "shll $3,%esi\n" "xorl %esi,%eax\n"
    "andl $65535,%edx\n" "xorl %edx,%eax\n"
    "movabsq $0xdeadbeefcafe0000,%r10\n" "orq %r10,%rax\n"
    CLOBBER "ret\n"
    ".size narrow_dirty_constants,.-narrow_dirty_constants\n"
    ".globl narrow_seed\n" ".type narrow_seed,@function\n"
    "narrow_seed:\n" "movl %edi,%eax\n" "andl $1,%eax\n"
    CLOBBER "ret\n" ".size narrow_seed,.-narrow_seed\n"
    ".globl narrow_record\n" ".type narrow_record,@function\n"
    "narrow_record:\n" "andl $1,%edi\n"
    "movq %rdi,narrow_recorded(%rip)\n"
    CLOBBER "ret\n" ".size narrow_record,.-narrow_record\n"
);

int main(void) {
    const uint64_t values[] = {
        0, 1, 7, 128, 65535, 65536, UINT64_MAX, UINT64_C(0xdeadbeefcafe1234)
    };
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    uint64_t (*const functions[])(uint64_t, uint64_t, uint64_t *) = {
        narrow_entry_1, narrow_entry_3, narrow_entry_8, narrow_entry_16,
        narrow_return_1, narrow_return_3, narrow_return_8, narrow_return_16,
        narrow_call_3, narrow_call_8, narrow_call_16, narrow_constants
    };
    const uint64_t masks[] = { 1, 7, 255, 65535, 1, 7, 255, 65535, 7, 255, 65535, 65535 };
    unsigned observations = 0;
    for (unsigned a = 0; a < 8; ++a) for (unsigned b = 0; b < 8; ++b) {
        for (unsigned f = 0; f < 12; ++f) {
            const uint64_t mask = masks[f];
            uint64_t payload, expected, return_mask = UINT64_MAX;
            if (f < 4) {
                payload = values[a] & mask;
                expected = payload ^ values[b];
            } else if (f < 8) {
                payload = (values[a] ^ values[b]) & mask;
                expected = payload;
                /* A narrow return defines only its low payload bits. */
                return_mask = mask;
            } else {
                payload = f == 11 ? (4 ^ (255 << 3) ^ 32768) : ((values[a] ^ 90) & mask);
                expected = payload ^ values[a] ^ values[b];
            }
            uint64_t output[] = { guard, UINT64_MAX, guard };
            const uint64_t actual = functions[f](values[a], values[b], &output[1]) & return_mask;
            if (actual != expected || output[1] != payload || output[0] != guard || output[2] != guard) {
                fprintf(stderr, "narrow ABI mismatch function=%u input=%u live=%u actual=%llx expected=%llx output=%llx payload=%llx\n",
                        f, a, b, (unsigned long long)actual, (unsigned long long)expected,
                        (unsigned long long)output[1], (unsigned long long)payload);
                return 1;
            }
            ++observations;
        }
        narrow_recorded = UINT64_MAX;
        narrow_last_use(values[a] ^ values[b]);
        if (narrow_recorded != ((values[a] ^ values[b]) & 1)) return 2;
        ++observations;
    }
    printf("narrow-abi observations=%u parameters=returns=calls=constants=last-use=live=guards=preserved\n", observations);
    return 0;
}
