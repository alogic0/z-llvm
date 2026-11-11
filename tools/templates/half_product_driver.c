#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned observations, fault;

static unsigned is_nan(uint16_t value) {
    return (value & 0x7c00) == 0x7c00 && (value & 0x03ff) != 0;
}

static uint32_t rounded_shift(uint32_t value, unsigned shift) {
    if (!shift) return value;
    uint32_t result = value >> shift;
    uint32_t remainder = value & ((UINT32_C(1) << shift) - 1);
    uint32_t halfway = UINT32_C(1) << (shift - 1);
    return result + (remainder > halfway || (remainder == halfway && (result & 1)));
}

/* Decode integer significands, multiply exactly, then round once to binary16.
   No C floating type, conversion or arithmetic participates in this oracle. */
static uint16_t oracle(uint16_t left, uint16_t right) {
    unsigned sign = (left ^ right) & 0x8000;
    unsigned a = left & 0x7fff, b = right & 0x7fff;
    if (is_nan(left) || is_nan(right) || (a == 0x7c00 && b == 0) || (b == 0x7c00 && a == 0))
        return 0x7e00;
    if (a == 0x7c00 || b == 0x7c00) return (uint16_t)(sign | 0x7c00);
    if (!a || !b) return (uint16_t)sign;
    unsigned ea = a >> 10, eb = b >> 10;
    uint32_t sa = (a & 0x3ff) | (ea ? 0x400 : 0);
    uint32_t sb = (b & 0x3ff) | (eb ? 0x400 : 0);
    uint32_t product = sa * sb;
    int exponent = (ea ? (int)ea - 25 : -24) + (eb ? (int)eb - 25 : -24);
    unsigned top = 0;
    for (uint32_t scan = product; scan > 1; scan >>= 1) ++top;
    int unbiased = (int)top + exponent;
    if (unbiased < -14) {
        int scale = exponent + 24;
        uint32_t fraction = scale >= 0 ? product << (unsigned)scale : rounded_shift(product, (unsigned)-scale);
        return (uint16_t)(sign | fraction);
    }
    uint32_t significand = top > 10 ? rounded_shift(product, top - 10) : product << (10 - top);
    if (significand == 0x800) { significand = 0x400; ++unbiased; }
    if (unbiased > 15) return (uint16_t)(sign | 0x7c00);
    return (uint16_t)(sign | ((unsigned)(unbiased + 15) << 10) | (significand - 0x400));
}

/* Scale the exact integer ratio to the destination ULP and use its remainder
   for ties-to-even rounding. No wider floating arithmetic or helper is used. */
static uint16_t division_oracle(uint16_t left, uint16_t right) {
    unsigned sign = (left ^ right) & 0x8000;
    unsigned a = left & 0x7fff, b = right & 0x7fff;
    if (is_nan(left) || is_nan(right) || (!a && !b) || (a == 0x7c00 && b == 0x7c00))
        return 0x7e00;
    if (a == 0x7c00 || !b) return (uint16_t)(sign | 0x7c00);
    if (b == 0x7c00 || !a) return (uint16_t)sign;
    unsigned ea = a >> 10, eb = b >> 10;
    uint64_t sa = (a & 0x3ff) | (ea ? 0x400 : 0);
    uint64_t sb = (b & 0x3ff) | (eb ? 0x400 : 0);
    int exponent = (ea ? (int)ea - 25 : -24) - (eb ? (int)eb - 25 : -24);
    uint64_t n = sa, d = sb;
    int unbiased = exponent;
    while (n < d) { n <<= 1; --unbiased; }
    while (n >= 2*d) { d <<= 1; ++unbiased; }
    if (unbiased > 15) return (uint16_t)(sign | 0x7c00);
    int scale = exponent + (unbiased < -14 ? 24 : 10 - unbiased);
    n = sa;
    d = sb;
    if (scale >= 0) n <<= (unsigned)scale;
    else d <<= (unsigned)-scale;
    uint64_t rounded = n / d, remainder = n % d;
    rounded += remainder > d - remainder || (remainder == d - remainder && (rounded & 1));
    if (unbiased < -14) return (uint16_t)(sign | rounded);
    if (rounded == 0x800) { rounded = 0x400; ++unbiased; }
    if (unbiased > 15) return (uint16_t)(sign | 0x7c00);
    return (uint16_t)(sign | ((unsigned)(unbiased + 15) << 10) | (rounded - 0x400));
}

static unsigned matches(uint16_t expected, uint16_t actual) {
    return is_nan(expected) ? is_nan(actual) : expected == actual;
}

static int mismatch(unsigned which, uint16_t a, uint16_t b, const char *stage) {
    fprintf(stderr, "half product mismatch case=%u a=%04x b=%04x stage=%s fault=%u observation=%u\n",
            which, a, b, stage, fault, observations);
    return 1;
}

static int check(unsigned which, uint16_t a, uint16_t b) {
    const unsigned mode = cases[which].mode;
    const uint16_t left = mode == 1 ? cases[which].constant : a;
    const uint16_t right = mode == 2 ? cases[which].constant : b;
    const unsigned operation = cases[which].operation;
    const uint16_t expected = operation == 2 ? left ^ 0x8000 : operation == 1 ? division_oracle(left, right) : oracle(left, right);
    uint64_t live = (uint64_t)a * UINT64_C(0x9e3779b97f4a7c15) ^ ((uint64_t)b << 32) ^ which;
    uint64_t e1 = ~live + a, e2 = live ^ b;
    uint64_t e3 = ((uint64_t)a << 48) | ((uint64_t)b << 16) | which;
    uint64_t e4 = live + UINT64_C(0x5566778899aabbcc);
    uint64_t mixed = ((((live ^ e1) + e2) ^ e3) + e4) ^ a ^ b;
    uint8_t guarded[8];
    memset(guarded, 0xa7, sizeof(guarded));
    uint8_t *out = guarded + 1;
    memcpy(out, &a, sizeof(a));
    uint64_t actual = cases[which].run(a, b, live, e1, e2, e3, e4, out);
    if (fault == 1) actual ^= 1;
    if (fault == 2) out[0] ^= 1;
    if (fault == 3) out[2] ^= 1;
    uint64_t decoded = actual ^ mixed;
    if (decoded > UINT16_MAX || (operation == 2 ? expected != (uint16_t)decoded : !matches(expected, (uint16_t)decoded)))
        return mismatch(which, a, b, "return-live");
    uint16_t stored;
    memcpy(&stored, out, sizeof(stored));
    if (operation == 2 ? expected != stored : !matches(expected, stored)) return mismatch(which, a, b, "stored-bits");
    if (guarded[0] != 0xa7) return mismatch(which, a, b, "prefix-guard");
    for (unsigned i = 3; i < sizeof(guarded); ++i)
        if (guarded[i] != 0xa7) return mismatch(which, a, b, "suffix-guard");
    ++observations;
    return 0;
}

int main(int argc, char **argv) {
    if (argc == 2) fault = (unsigned)strtoul(argv[1], 0, 10);
    if (argc > 2 || fault > 3) return 2;
    const uint16_t counters[] = {
        0x0000, 0x0001, 0x03ff, 0x0400, 0x3555, 0x3bff,
        0x3c00, 0x3c01, 0x4000, 0x70e2, 0x7bff, 0x7c00,
        0x7d01, 0x7e55, 0x8000, 0xbc00, 0xfbff, 0xfc00
    };
    for (unsigned k = 0; k < sizeof(cases) / sizeof(cases[0]); ++k)
        for (unsigned a = 0; a <= UINT16_MAX; ++a) {
            if (!cases[k].mode) {
                for (unsigned b = 0; b < sizeof(counters) / sizeof(counters[0]); ++b)
                    if (check(k, (uint16_t)a, counters[b])) return 1;
            } else if (check(k, (uint16_t)a, (uint16_t)(a * 40503U + 17U * k))) return 1;
        }
    if (observations != 9371648) return mismatch(0, 0, 0, "count");
    puts("half-product observations=9371648 multiplication=division=negation=rounding=classes=bits=live=loads=stores=guards=preserved");
    return 0;
}
