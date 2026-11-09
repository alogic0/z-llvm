#include <stdint.h>
#include <stdio.h>

typedef uint64_t (*function_t)(uint64_t, uint64_t, uint64_t, uint64_t *);
#define DECLARE(name) extern uint64_t name(uint64_t, uint64_t, uint64_t, uint64_t *)
#define DECLARE_WIDTH(bits) \
    DECLARE(frontier_ssub##bits); DECLARE(frontier_ssub##bits##_left); DECLARE(frontier_ssub##bits##_right); \
    DECLARE(frontier_sadd##bits); DECLARE(frontier_sadd##bits##_left); DECLARE(frontier_sadd##bits##_right)
DECLARE_WIDTH(8); DECLARE_WIDTH(16); DECLARE_WIDTH(32); DECLARE_WIDTH(64); DECLARE_WIDTH(96);
DECLARE(frontier_scmp32); DECLARE(frontier_scmp32_left);
DECLARE(frontier_ctlz128); DECLARE(frontier_ctlz128_poison);
DECLARE(frontier_abs32); DECLARE(frontier_abs64);
DECLARE(frontier_abs32_ignored); DECLARE(frontier_abs64_ignored);
DECLARE(frontier_mul_sat16); DECLARE(frontier_mul_sat16_left); DECLARE(frontier_mul_sat16_right);
DECLARE(frontier_ushl64_one); DECLARE(frontier_ushl64_one_constant);

static const uint64_t key = UINT64_C(0xfeedface12345678);
__attribute__((noinline)) uint64_t frontier_clobber(uint64_t input) {
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
#define WIDTH(bits) frontier_ssub##bits, frontier_ssub##bits##_left, frontier_ssub##bits##_right, \
    frontier_sadd##bits, frontier_sadd##bits##_left, frontier_sadd##bits##_right
    WIDTH(8), WIDTH(16), WIDTH(32), WIDTH(64), WIDTH(96),
    frontier_scmp32, frontier_scmp32_left, frontier_ctlz128, frontier_ctlz128_poison,
    frontier_abs32, frontier_abs64, frontier_abs32_ignored, frontier_abs64_ignored,
    frontier_mul_sat16, frontier_mul_sat16_left, frontier_mul_sat16_right,
    frontier_ushl64_one, frontier_ushl64_one_constant
};
static unsigned observations;

static int64_t signed_value(uint64_t value, unsigned bits) {
    uint64_t modulus = UINT64_C(1) << bits;
    uint64_t raw = value & (modulus - 1);
    return raw < modulus / 2 ? (int64_t)raw : (int64_t)raw - (int64_t)modulus;
}

typedef unsigned __int128 u128;
static u128 expected_value(unsigned which, uint64_t a, uint64_t b) {
    if (which < 30) {
        const unsigned widths[] = {8,16,32,64,96};
        unsigned bits = widths[which / 6], variant = which % 3;
        u128 modulus = (u128)1 << bits, sign = modulus >> 1, mask = modulus - 1;
        u128 raw_left = bits == 96 ? (u128)a | ((u128)(uint32_t)b << 64) : (u128)a & mask;
        u128 raw_right = bits == 96 ? (u128)b | ((u128)(uint32_t)a << 64) : (u128)b & mask;
        __int128 minimum = -(__int128)sign, maximum = -minimum - 1;
        __int128 left = variant == 1 ? minimum : (raw_left & sign ? (__int128)raw_left - (__int128)modulus : (__int128)raw_left);
        __int128 right = variant == 2 ? -1 : (raw_right & sign ? (__int128)raw_right - (__int128)modulus : (__int128)raw_right);
        __int128 difference = which % 6 >= 3 ? left + right : left - right;
        if (difference < minimum) difference = minimum;
        if (difference > maximum) difference = maximum;
        return (u128)difference & mask;
    }
    if (which < 32) {
        int64_t left = which == 31 ? 0 : signed_value(a, 32), right = signed_value(b, 32);
        int32_t result = left < right ? -1 : left > right ? 1 : 0;
        return (uint32_t)result;
    }
    if (which < 34) {
        unsigned count = 0;
        for (int bit = 63; bit >= 0; --bit) {
            if ((b >> bit) & 1) return count;
            ++count;
        }
        for (int bit = 63; bit >= 0; --bit) {
            if ((a >> bit) & 1) return count;
            ++count;
        }
        return count;
    }
    if (which < 36) {
        uint64_t value = which == 34 ? (uint32_t)a : a;
        uint64_t sign = UINT64_C(1) << (which == 34 ? 31 : 63);
        uint64_t result = value & sign ? UINT64_C(0) - value : value;
        return which == 34 ? (uint32_t)result : result;
    }
    if (which < 38) return b;
    if (which < 41) {
        uint64_t left = which == 39 ? UINT16_MAX : (uint16_t)a;
        uint64_t right = which == 40 ? UINT16_MAX : (uint16_t)b;
        uint64_t product = left * right;
        return product > UINT16_MAX ? UINT16_MAX : product;
    }
    u128 doubled = (u128)(which == 42 ? UINT64_MAX : a) * 2;
    return doubled > UINT64_MAX ? UINT64_MAX : doubled;
}

static int check(unsigned which, uint64_t a, uint64_t b, uint64_t salt) {
    /* Compare only defined, observed intrinsic results. Separate ignored-result
       functions exercise INT_MIN poison inputs without demanding a value. */
    if (which == 33 && !(a | b)) a = 1;
    if (which == 34 && (uint32_t)a == UINT32_C(0x80000000)) a ^= 1;
    if (which == 35 && a == (UINT64_C(1) << 63)) a ^= 1;
    const uint64_t guard = UINT64_C(0xa55a1234deadbeef);
    struct { uint64_t before, words[4], after; } output = { guard, {0,0,0,0}, guard };
    uint64_t first = salt ^ key, second = a ^ key;
    u128 expected = expected_value(which, a, b);
    uint64_t expected_return = ((((a + b) ^ salt) + first) ^ second);
    uint64_t result = functions[which](a, b, salt, output.words);
    if (result != expected_return || output.words[0] != (uint64_t)expected || output.words[1] != (uint64_t)(expected >> 64) ||
        output.words[2] != first || output.words[3] != second || output.before != guard || output.after != guard) {
        fprintf(stderr, "function=%u a=%016llx b=%016llx value=%016llx expected=%016llx high=%016llx expected_high=%016llx first=%016llx expected_first=%016llx second=%016llx expected_second=%016llx live=%016llx expected_live=%016llx\n",
                which, (unsigned long long)a, (unsigned long long)b,
                (unsigned long long)output.words[0], (unsigned long long)expected,
                (unsigned long long)output.words[1], (unsigned long long)(expected >> 64),
                (unsigned long long)output.words[2], (unsigned long long)first,
                (unsigned long long)output.words[3], (unsigned long long)second,
                (unsigned long long)result, (unsigned long long)expected_return);
        return 1;
    }
    ++observations;
    return 0;
}

int main(void) {
    const uint64_t values[] = {
        0,1,2,0x7f,0x80,0xff,0x7fffffff,0x80000000,0xffffffff,
        UINT64_C(0x7fffffffffffffff), UINT64_C(0x8000000000000000),
        UINT64_C(0xdeadbeef89abcdef), UINT64_C(0xaaaaaaaa55555555),
        UINT64_C(0xffffffff00000080), UINT64_C(0x1234567880000001), UINT64_MAX
    };
    for (unsigned which = 0; which < sizeof functions / sizeof functions[0]; ++which)
        for (unsigned i = 0; i < 16; ++i) for (unsigned j = 0; j < 16; ++j)
            if (check(which, values[i], values[j], UINT64_C(0x123456789abcdef0) ^ (i * 257 + j))) return 1;
    for (unsigned which = 32; which < 34; ++which) for (unsigned bit = 0; bit < 128; ++bit) {
        uint64_t a = bit < 64 ? UINT64_C(1) << bit : 0;
        uint64_t b = bit >= 64 ? UINT64_C(1) << (bit - 64) : 0;
        if (check(which, a, b, UINT64_C(0xfedcba9876543210) + bit)) return 1;
    }
    if (observations != 11264) return 2;
    puts("integer-intrinsic-frontier observations=11264 signed=wide=poison=clobbers=live=guards=preserved");
    return 0;
}
