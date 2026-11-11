#include <stdint.h>
typedef uint64_t (*freeze_fn)(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_0_0(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_0_1(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_0_2(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_0_3(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_1_0(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_1_1(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_1_2(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_1_3(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_2_0(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_2_1(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_2_2(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_2_3(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_3_0(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_3_1(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_3_2(uint64_t,uint64_t,uint64_t,uint8_t*);
extern uint64_t word_pair_freeze_3_3(uint64_t,uint64_t,uint64_t,uint8_t*);
static const struct { freeze_fn run; unsigned variant; } cases[]={
 {word_pair_freeze_0_0,0},
 {word_pair_freeze_0_1,1},
 {word_pair_freeze_0_2,2},
 {word_pair_freeze_0_3,3},
 {word_pair_freeze_1_0,0},
 {word_pair_freeze_1_1,1},
 {word_pair_freeze_1_2,2},
 {word_pair_freeze_1_3,3},
 {word_pair_freeze_2_0,0},
 {word_pair_freeze_2_1,1},
 {word_pair_freeze_2_2,2},
 {word_pair_freeze_2_3,3},
 {word_pair_freeze_3_0,0},
 {word_pair_freeze_3_1,1},
 {word_pair_freeze_3_2,2},
 {word_pair_freeze_3_3,3},
};
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned observations, fault;

__attribute__((noinline)) void word_pair_freeze_clobber(void) {
    __asm__ volatile(
        "xorq %%rax,%%rax\n\txorq %%rcx,%%rcx\n\txorq %%rdx,%%rdx\n\t"
        "xorq %%rdi,%%rdi\n\txorq %%rsi,%%rsi\n\txorq %%r8,%%r8\n\t"
        "xorq %%r9,%%r9\n\txorq %%r10,%%r10\n\txorq %%r11,%%r11"
        : : : "rax", "rcx", "rdx", "rdi", "rsi", "r8", "r9", "r10", "r11", "cc", "memory");
}

static int mismatch(unsigned which, unsigned input, unsigned seed, const char *stage) {
    fprintf(stderr, "word pair freeze mismatch case=%u input=%u seed=%u stage=%s fault=%u observation=%u\n",
            which, input, seed, stage, fault, observations);
    return 1;
}

int main(int argc, char **argv) {
    if (argc == 2) fault = (unsigned)strtoul(argv[1], 0, 10);
    if (argc > 2 || fault > 3) return 2;
    const uint64_t values[] = {
        0, 1, 2, 3, 127, 255, UINT32_MAX, UINT64_C(1) << 32,
        UINT64_C(0x123456789abcdef0), UINT64_C(1) << 51,
        (UINT64_C(1) << 52) - 1, UINT64_C(1) << 52,
        (UINT64_C(1) << 53) - 1, UINT64_C(1) << 63,
        UINT64_C(0xdeadbeef12345678), UINT64_MAX
    };
    const uint64_t seeds[] = {0, 1, UINT64_C(0xa55a55aa12345678), UINT64_MAX};
    for (unsigned k = 0; k < sizeof(cases) / sizeof(cases[0]); ++k)
        for (unsigned a = 0; a < 16; ++a) for (unsigned s = 0; s < 4; ++s) {
            uint8_t guarded[48];
            memset(guarded, 0xa7, sizeof(guarded));
            uint8_t *out = guarded + 1;
            uint64_t first = values[a], second = values[(a + 5 * s) & 15], live = seeds[s];
            unsigned variant = cases[k].variant;
            uint64_t known_first = variant == 3 ? 0 : first;
            uint64_t known_second = variant == 0 ? second : 0;
            uint64_t expected = known_first ^ known_second ^ live;
            uint64_t actual = cases[k].run(first, second, live, out);
            if (fault == 1) actual ^= 1;
            if (fault == 2) out[0] ^= 1;
            if (fault == 3) out[32] ^= 1;
            if (actual != expected) return mismatch(k, a, s, "return-defined");
            uint64_t stored[4];
            memcpy(stored, out, sizeof(stored));
            if (stored[0] != known_first || stored[0] != stored[2] || stored[1] != stored[3])
                return mismatch(k, a, s, "defined-stable-stores");
            if ((variant == 0 || variant == 3) && stored[1] != known_second)
                return mismatch(k, a, s, "second-defined");
            if (guarded[0] != 0xa7) return mismatch(k, a, s, "prefix-guard");
            for (unsigned i = 33; i < sizeof(guarded); ++i)
                if (guarded[i] != 0xa7) return mismatch(k, a, s, "suffix-guard");
            ++observations;
        }
    if (observations != 1024) return mismatch(0, 0, 0, "count");
    puts("word-pair-freeze observations=1024 defined=stable=clobbers=stores=guards=preserved");
    return 0;
}
