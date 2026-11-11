// Calls use the exact captured compiler-rt ABI, including boxed half payloads.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { uint16_t real, imag; } half_pair;
typedef struct { long double real, imag; } extended_pair;
typedef struct { __float128 real, imag; } quad_pair;
extern void mulh(half_pair *, double, double, double, double) __asm__("__mulhc3");
extern void divh(half_pair *, double, double, double, double) __asm__("__divhc3");
extern void divx(extended_pair *, long double, long double, long double, long double) __asm__("__divxc3");
extern void divq(quad_pair *, __float128, __float128, __float128, __float128) __asm__("__divtc3");
extern void mulq(quad_pair *, __float128, __float128, __float128, __float128) __asm__("__multc3");
extern float _Complex muls(float, float, float, float) __asm__("__mulsc3");
extern float _Complex divs(float, float, float, float) __asm__("__divsc3");
extern double _Complex muld(double, double, double, double) __asm__("__muldc3");
extern double _Complex divd(double, double, double, double) __asm__("__divdc3");
extern long double sqrtx(long double) __asm__("sqrtl");
extern __float128 sqrtq(__float128) __asm__("sqrtf128");
extern double sqrth(double) __asm__("__sqrth");
extern double unsigned_double(const void *, uint64_t) __asm__("__floatuneidf");
extern float unsigned_float(const void *, uint64_t) __asm__("__floatuneisf");
extern double unsigned_half(const void *, uint64_t) __asm__("__floatuneihf");
extern double signed_double(const void *, uint64_t) __asm__("__floateidf");
extern float signed_float(const void *, uint64_t) __asm__("__floateisf");
extern double signed_half(const void *, uint64_t) __asm__("__floateihf");
extern double unsigned128_double(unsigned __int128) __asm__("__floatuntidf");
extern float unsigned128_float(unsigned __int128) __asm__("__floatuntisf");
extern long double unsigned128_extended(unsigned __int128) __asm__("__floatuntixf");
extern __float128 unsigned128_quad(unsigned __int128) __asm__("__floatuntitf");
extern int compare128(uint64_t, uint64_t, uint64_t, uint64_t) __asm__("__ucmpti2");
extern int compare64(uint64_t,uint64_t) __asm__("__ucmpdi2");
extern int compare32(uint32_t,uint32_t) __asm__("__ucmpsi2");
extern int signed_compare64(int64_t,int64_t) __asm__("__cmpdi2");
extern unsigned __int128 swap128(uint64_t, uint64_t) __asm__("__bswapti2");
extern unsigned __int128 reverse128(uint64_t, uint64_t) __asm__("__bitreverseti2");

static double boxed(uint16_t bits) { uint64_t word = bits; double value; memcpy(&value, &word, 8); return value; }
static uint16_t half_bits(double value) { uint64_t word; memcpy(&word, &value, 8); return (uint16_t)word; }
static unsigned __int128 reverse_bits(unsigned __int128 value) {
    unsigned __int128 result = 0;
    for (unsigned i = 0; i < 128; ++i) { result = (result << 1) | (value & 1); value >>= 1; }
    return result;
}

int main(int argc, char **argv) {
    unsigned fault = argc > 1 ? (unsigned)strtoul(argv[1], 0, 10) : 0;
    size_t observations = 0;
#define CHECK(c) do { ++observations; if (!(c)) { fprintf(stderr, "runtime-completion line=%d observation=%zu fault=%u\n", __LINE__, observations, fault); return 1; } } while (0)
    struct { uint64_t before; half_pair value; unsigned char after[12]; } h;
    memset(&h, 0xa5, sizeof h);
    mulh(&h.value, boxed(0x3c00), boxed(0x4000), boxed(0x4200), boxed(0x4400));
    CHECK((h.value.real ^ (fault == 1)) == 0xc500); // -5
    CHECK(h.value.imag == 0x4900); // 10
    CHECK(h.before == UINT64_C(0xa5a5a5a5a5a5a5a5));
    for (unsigned i = 0; i < sizeof h.after; ++i) CHECK(h.after[i] == 0xa5);
    divh(&h.value, boxed(0x4400), boxed(0x4000), boxed(0x4000), boxed(0));
    CHECK(h.value.real == 0x4000 && h.value.imag == 0x3c00);
    extended_pair x;
    divx(&x, 4.L, 2.L, 2.L, 0.L);
    CHECK(x.real == 2.L && x.imag == 1.L);
    quad_pair q;
    divq(&q, 4.Q, 2.Q, 2.Q, 0.Q);
    CHECK(q.real == 2.Q && q.imag == 1.Q);
    mulq(&q, 1.Q, 2.Q, 3.Q, 4.Q);
    CHECK(q.real == -5.Q && q.imag == 10.Q);
    float _Complex cs = muls(1.f, 2.f, 3.f, 4.f);
    CHECK(__real__ cs == -5.f && __imag__ cs == 10.f);
    cs = divs(4.f, 2.f, 2.f, 0.f);
    CHECK(__real__ cs == 2.f && __imag__ cs == 1.f);
    double _Complex cd = muld(1., 2., 3., 4.);
    CHECK(__real__ cd == -5. && __imag__ cd == 10.);
    cd = divd(4., 2., 2., 0.);
    CHECK(__real__ cd == 2. && __imag__ cd == 1.);
    for (unsigned i = 0; i <= 8; ++i) {
        CHECK(sqrtx((long double)i * i) == i);
        CHECK(sqrtq((__float128)i * i) == i);
    }
    CHECK(half_bits(sqrth(boxed(0x4400))) == 0x4000); // sqrt(4) = 2
    for (unsigned bits = 65; bits <= 128; ++bits) {
        unsigned char integer[16] = {0}; integer[0] = 123;
        CHECK(unsigned_double(integer, bits) == 123.);
        CHECK(unsigned_float(integer, bits) == 123.f);
        CHECK(half_bits(unsigned_half(integer, bits)) == 0x57b0);
        CHECK(signed_double(integer, bits) == 123.);
        CHECK(signed_float(integer, bits) == 123.f);
        CHECK(half_bits(signed_half(integer, bits)) == 0x57b0);
        memset(integer, 0xff, sizeof integer); integer[0] = (unsigned char)-123;
        CHECK(signed_double(integer, bits) == -123.);
        CHECK(signed_float(integer, bits) == -123.f);
        CHECK(half_bits(signed_half(integer, bits)) == 0xd7b0);
    }
    for (unsigned shift = 0; shift < 128; ++shift) {
        unsigned __int128 value = (unsigned __int128)1 << shift;
        // Repeated multiplication is independent of the runtime integer casts.
        double d = 1.; float f = 1.f; long double e = 1.L; __float128 v = 1.Q;
        for (unsigned i = 0; i < shift; ++i) { d *= 2.; f *= 2.f; e *= 2.L; v *= 2.Q; }
        CHECK(unsigned128_double(value) == d);
        CHECK(unsigned128_float(value) == f);
        CHECK(unsigned128_extended(value) == e);
        CHECK(unsigned128_quad(value) == v);
    }
    const uint64_t words[] = {0, 1, UINT64_MAX, UINT64_C(0x8000000000000000), UINT64_C(0x0123456789abcdef)};
    for (unsigned a = 0; a < 5; ++a) for (unsigned b = 0; b < 5; ++b) {
        unsigned __int128 value = ((unsigned __int128)words[b] << 64) | words[a];
        unsigned __int128 other = ((unsigned __int128)words[a] << 64) | words[b];
        CHECK(compare128(words[a], words[b], words[b], words[a]) == (value < other ? 0 : value == other ? 1 : 2));
        CHECK(compare64(words[a],words[b]) == (words[a] < words[b] ? 0 : words[a] == words[b] ? 1 : 2));
        CHECK(compare32((uint32_t)words[a],(uint32_t)words[b]) == ((uint32_t)words[a] < (uint32_t)words[b] ? 0 : (uint32_t)words[a] == (uint32_t)words[b] ? 1 : 2));
        CHECK(signed_compare64((int64_t)words[a],(int64_t)words[b]) == ((int64_t)words[a] < (int64_t)words[b] ? 0 : (int64_t)words[a] == (int64_t)words[b] ? 1 : 2));
        unsigned __int128 swapped = ((unsigned __int128)__builtin_bswap64(words[a]) << 64) | __builtin_bswap64(words[b]);
        CHECK((swap128(words[a], words[b]) ^ (fault == 2)) == swapped);
        CHECK((reverse128(words[a], words[b]) ^ (fault == 3)) == reverse_bits(value));
    }
    printf("runtime-completion observations=%zu complex=conversion=sqrt=integer=preserved\n", observations);
    return 0;
}
