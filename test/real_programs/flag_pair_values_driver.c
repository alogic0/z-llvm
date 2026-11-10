#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef unsigned __int128 u128;
typedef uint64_t (*function_t)(uint64_t, uint64_t, uint64_t, uint64_t *);
#define DECLARE(name) extern uint64_t name(uint64_t, uint64_t, uint64_t, uint64_t *)
DECLARE(flag_pair_overflow8); DECLARE(flag_pair_overflow16);
DECLARE(flag_pair_overflow32); DECLARE(flag_pair_overflow64); DECLARE(flag_pair_overflow128);
DECLARE(flag_pair_atomic8); DECLARE(flag_pair_atomic16);
DECLARE(flag_pair_atomic32); DECLARE(flag_pair_atomic64); DECLARE(flag_pair_select);
DECLARE(flag_pair_freeze);

static const uint64_t key = UINT64_C(0xfeedface12345678);
__attribute__((noinline)) uint64_t flag_pair_clobber(uint64_t input) {
    uint64_t result = input ^ key;
    __asm__ volatile(
        "movabs $0x1111111133333333, %%rcx\n\t"
        "movabs $0x2222222244444444, %%rdx\n\t"
        "movabs $0x3333333355555555, %%rdi\n\t"
        "movabs $0x4444444466666666, %%rsi\n\t"
        "movabs $0x5555555577777777, %%r8\n\t"
        "movabs $0x6666666688888888, %%r9\n\t"
        "movabs $0x7777777799999999, %%r10\n\t"
        "movabs $0x88888888aaaaaaaa, %%r11\n\t"
        : "+a"(result) : : "rdi", "rsi", "rdx", "rcx", "r8", "r9", "r10", "r11", "memory", "cc");
    return result;
}

static const function_t functions[] = {
    flag_pair_overflow8, flag_pair_overflow16, flag_pair_overflow32,
    flag_pair_overflow64, flag_pair_overflow128,
    flag_pair_atomic8, flag_pair_atomic16, flag_pair_atomic32, flag_pair_atomic64,
    flag_pair_select, flag_pair_freeze
};
static const unsigned widths[] = {8,16,32,64,128,8,16,32,64,64,64};
static unsigned observations;
static unsigned inject_fault;

static int check(unsigned which, uint64_t a, uint64_t b, uint64_t salt, unsigned miss) {
    const unsigned bits = widths[which];
    const u128 mask = bits == 128 ? (u128)-1 : ((u128)1 << bits) - 1;
    const u128 left = bits == 128 ? (u128)a | (u128)b << 64 : (u128)a & mask;
    const u128 right = bits == 128 ? (u128)b | (u128)a << 64 : (u128)b & mask;
    const int choose = salt & 1;
    uint64_t box[8] = {key, 0,0,0,0, 0, key ^ 1, key ^ 2};
    uint64_t *out = box + 1;
    u128 value;
    uint64_t flag, memory;
    if (which < 5) {
        value = (choose ? left + right : left - right) & mask;
        flag = choose ? value < left : left < right;
        if (((salt >> 1) & 7) % 2) { value = 17; flag = 1; }
        memory = UINT64_C(0xa5a5a5a512345678);
    } else if (which < 9) {
        const uint64_t low_mask = (uint64_t)mask;
        const uint64_t expected = (uint64_t)(choose ? left : right);
        const uint64_t desired = (uint64_t)(choose ? right : left);
        const uint64_t old = miss ? (expected ^ 1) : expected;
        out[4] = (UINT64_C(0xa5a5a5a512345678) & ~low_mask) | old;
        value = old;
        flag = !miss;
        memory = (out[4] & ~low_mask) | (miss ? old : desired);
    } else if (which == 9) {
        value = choose ? a : b;
        flag = choose ? a < b : a > b;
        memory = UINT64_C(0xa5a5a5a512345678);
    } else {
        value = UINT64_C(0x100000001);
        flag = 1;
        memory = UINT64_C(0xa5a5a5a512345678);
    }
    if (which < 5 || which >= 9) out[4] = memory;
    const uint64_t low = (uint64_t)value, high = (uint64_t)(value >> 64);
    const uint64_t clobber = salt ^ key;
    uint64_t result = functions[which](a,b,salt,out);
    /* Calibrate each observation channel against independently compiled LLVM
       as well as local objects. Faults affect observations, never the oracle. */
    if (inject_fault == 1) result ^= 1;
    if (inject_fault == 2) out[2] ^= 1;
    if (inject_fault == 3) out[4] ^= 1;
    if (inject_fault == 4) box[0] ^= 1;
    if (inject_fault == 5) out[1] ^= 1;
    if (result != (low ^ high ^ flag ^ clobber) || out[0] != low || out[1] != high ||
        out[2] != flag || out[3] != clobber || out[4] != memory || box[0] != key ||
        box[6] != (key ^ 1) || box[7] != (key ^ 2)) {
        fprintf(stderr, "flag-pair mismatch function=%u a=%llx b=%llx salt=%llx miss=%u fault=%u\n",
                which, (unsigned long long)a, (unsigned long long)b,
                (unsigned long long)salt, miss, inject_fault);
        return 1;
    }
    ++observations;
    return 0;
}

int main(int argc, char **argv) {
    if (argc == 2) inject_fault = (unsigned)strtoul(argv[1], NULL, 10);
    if (argc > 2 || inject_fault > 5) return 2;
    static const uint64_t values[] = {
        0,1,0x7f,0x80,0x7fffffff,0x80000000,UINT64_MAX-1,UINT64_MAX
    };
    static const uint64_t salts[] = {0,1,2,3,14,15,UINT64_C(0x123456789abcdef0),UINT64_MAX};
    for (unsigned which=0; which<11; ++which)
        for (unsigned i=0; i<8; ++i) for (unsigned j=0; j<8; ++j)
            for (unsigned k=0; k<8; ++k) for (unsigned miss=0; miss<2; ++miss)
                if (check(which, values[i], values[j], salts[k], miss)) return 1;
    printf("flag-pair-values observations=%u pairs=parallel=atomic=freeze=clobbers=guards=preserved\n", observations);
    return observations != 11264;
}
