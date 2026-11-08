#include <stdint.h>
#include <stdio.h>

extern uint64_t bit_pop32(uint64_t, uint64_t), bit_pop16(uint64_t, uint64_t), bit_pop64(uint64_t, uint64_t);
extern uint64_t bit_funnel64(uint64_t, uint64_t, uint64_t), bit_funnel16(uint64_t, uint64_t), bit_funnel6(uint64_t, uint64_t, uint64_t);
extern uint64_t bit_cttz37(uint64_t), bit_cttz23(uint64_t), bit_ctlz23(uint64_t), bit_ctlz8(uint64_t);
extern uint64_t bit_abs25(uint64_t), bit_abs29(uint64_t), bit_bswap48(uint64_t);
extern uint64_t bit_extrema64(uint64_t, uint64_t), bit_overflow64(uint64_t, uint64_t);

__attribute__((noinline)) uint64_t bit_intrinsic_clobber(uint64_t value) {
    uint64_t result = value ^ UINT64_C(0xfeedface12345678);
    __asm__ volatile("" : "+a"(result) : : "rdi", "rsi", "rdx", "rcx", "r8", "r9", "r10", "r11", "memory", "cc");
    return result;
}
static uint64_t mask(unsigned bits) { return bits == 64 ? UINT64_MAX : (UINT64_C(1) << bits) - 1; }
static unsigned pop(uint64_t x) { unsigned n = 0; while (x) { n += x & 1; x >>= 1; } return n; }
static unsigned trailing(uint64_t x, unsigned bits) { x &= mask(bits); unsigned n = 0; while (n < bits && !(x & 1)) { ++n; x >>= 1; } return n; }
static unsigned leading(uint64_t x, unsigned bits) { unsigned n = 0; while (n < bits && !(x & (UINT64_C(1) << (bits - n - 1)))) ++n; return n; }
static uint64_t absolute(uint64_t x, unsigned bits) { x &= mask(bits); return x & (UINT64_C(1) << (bits - 1)) ? (0 - x) & mask(bits) : x; }
static uint64_t funnel(uint64_t a, uint64_t b, uint64_t count, unsigned bits) {
    a &= mask(bits); b &= mask(bits); count = (count & mask(bits)) % bits;
    return count ? ((a << count) | (b >> (bits - count))) & mask(bits) : a;
}
static uint64_t swap48(uint64_t value) { uint64_t result = 0; for (unsigned n = 0; n < 6; ++n) { result = (result << 8) | (value & 255); value >>= 8; } return result; }

int main(void) {
    const uint64_t edges[] = {0, 1, 2, 31, 63, 64, 65, UINT64_MAX, UINT64_C(1) << 63, UINT64_C(1) << 36, UINT64_C(1) << 24, UINT64_C(1) << 28};
    uint64_t random = UINT64_C(0x0123456789abcdef);
    unsigned observations = 0;
    for (unsigned i = 0; i < 512; ++i) {
        random ^= random << 13; random ^= random >> 7; random ^= random << 17;
        uint64_t a = i < sizeof edges / sizeof edges[0] ? edges[i] : random;
        uint64_t b = edges[i % (sizeof edges / sizeof edges[0])] ^ (random >> 3);
        uint64_t count = i % 4 == 0 ? UINT64_MAX : i;
        uint64_t positive = (b & UINT32_MAX) | 1, sum = a + positive;
        uint64_t got[] = {bit_pop32(a,b), bit_pop16(a,b), bit_pop64(a,b), bit_funnel64(a,b,count), bit_funnel16(a,b), bit_funnel6(a,b,count), bit_cttz37(a), bit_cttz23(a), bit_ctlz23(a), bit_ctlz8(a), bit_abs25(a), bit_abs29(a), bit_bswap48(a), bit_extrema64(a,b), bit_overflow64(a,b)};
        uint64_t expected[] = {pop((uint32_t)a) ^ a ^ bit_intrinsic_clobber(b), pop((a & 65535) | 1) ^ b, pop(a | 1) ^ b, funnel(a,b,count,64) ^ b, funnel(a,a,12,16) ^ b, funnel(a,b,count,6) ^ a, trailing(a,37), trailing(a,23), leading(a,23), leading((a & 255) | 1,8), absolute(a,25), absolute(a,29), swap48(a), (a ? a : 1) ^ b, sum ^ (sum < a) ^ a};
        for (unsigned j = 0; j < 15; ++j) { if (got[j] != expected[j]) { fprintf(stderr,"case=%u operation=%u got=%llu expected=%llu\n",i,j,(unsigned long long)got[j],(unsigned long long)expected[j]); return 1; } ++observations; }
    }
    printf("integer-bit-intrinsics observations=%u widths=counts=facts=aliases=calls=preserved\n", observations);
    return 0;
}
