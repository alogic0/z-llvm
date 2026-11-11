#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned observations, fault;
static const u128 fraction_mask = ((u128)1 << 112) - 1;
static const u128 sign_mask = (u128)1 << 127;

typedef __float128 quad_carrier;
static u128 rotate(u128 value,unsigned shift) { return value << shift | value >> (128-shift); }
__attribute__((noinline)) static void clobber(void) {
    __asm__ volatile(
        "xor %%eax,%%eax\n\txor %%ecx,%%ecx\n\txor %%edx,%%edx\n\t"
        "xor %%edi,%%edi\n\txor %%esi,%%esi\n\txor %%r8d,%%r8d\n\t"
        "xor %%r9d,%%r9d\n\txor %%r10d,%%r10d\n\txor %%r11d,%%r11d\n\t"
        "pxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1\n\t"
        "pxor %%xmm2,%%xmm2\n\tpxor %%xmm3,%%xmm3\n\t"
        "pxor %%xmm4,%%xmm4\n\tpxor %%xmm5,%%xmm5\n\t"
        "pxor %%xmm6,%%xmm6\n\tpxor %%xmm7,%%xmm7\n\t"
        "pxor %%xmm8,%%xmm8\n\tpxor %%xmm9,%%xmm9\n\t"
        "pxor %%xmm10,%%xmm10\n\tpxor %%xmm11,%%xmm11\n\t"
        "pxor %%xmm12,%%xmm12\n\tpxor %%xmm13,%%xmm13\n\t"
        "pxor %%xmm14,%%xmm14\n\tpxor %%xmm15,%%xmm15"
        :::"rax","rcx","rdx","rdi","rsi","r8","r9","r10","r11",
        "xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7",
        "xmm8","xmm9","xmm10","xmm11","xmm12","xmm13","xmm14","xmm15","cc","memory");
}

/* The C floating type carries bits across the real ABI only. No C floating
   arithmetic or conversion participates in these providers or the oracles. */
__attribute__((noinline)) quad_carrier extended_mixed_quad(uint64_t before,u128 a,quad_carrier f,u128 b,uint64_t after) {
    u128 raw;
    memcpy(&raw,&f,16);
    u128 result = a + rotate(b,17) + raw + (((u128)before<<64) | after);
    clobber();
    memcpy(&f,&result,16);
    return f;
}
__attribute__((noinline)) u128 extended_mixed_integer(quad_carrier f,uint64_t scalar,u128 a) {
    u128 raw;
    memcpy(&raw,&f,16);
    u128 result = raw ^ rotate(a,29) ^ scalar;
    clobber();
    return result;
}

/* These numerical oracles use only integer representation arithmetic.
   They neither call conversion helpers nor use any C floating type. */
static u128 rounded_right(u128 value, unsigned shift) {
    if (!shift) return value;
    if (shift >= 128) return 0;
    u128 q = value >> shift, r = value & (((u128)1 << shift) - 1);
    u128 halfway = (u128)1 << (shift - 1);
    return q + (r > halfway || (r == halfway && (q & 1)));
}

static u128 integer_to_quad(u128 raw, unsigned is_signed) {
    unsigned negative = is_signed && (raw & sign_mask) != 0;
    u128 magnitude = negative ? ~raw + 1 : raw;
    if (!magnitude) return 0;
    unsigned top = 0;
    for (u128 scan = magnitude; scan > 1; scan >>= 1) ++top;
    u128 significand = top <= 112 ? magnitude << (112 - top) : rounded_right(magnitude, top - 112);
    if (significand == (u128)1 << 113) { significand >>= 1; ++top; }
    return (negative ? sign_mask : 0) | ((u128)(top + 16383) << 112) | (significand & fraction_mask);
}

static u128 half_to_quad(uint16_t raw) {
    u128 sign = (u128)(raw >> 15) << 127;
    unsigned exponent = (raw >> 10) & 31, fraction = raw & 1023;
    if (exponent == 31) return sign | ((u128)0x7fff << 112) | ((u128)fraction << 102);
    if (!exponent && !fraction) return sign;
    unsigned significand = fraction | (exponent ? 1024 : 0), top = 0;
    for (unsigned scan = significand; scan > 1; scan >>= 1) ++top;
    int unbiased = (exponent ? (int)exponent - 25 : -24) + (int)top;
    return sign | ((u128)(unbiased + 16383) << 112) | (((u128)significand << (112 - top)) & fraction_mask);
}

static uint16_t quad_to_half(u128 raw) {
    unsigned sign = (unsigned)(raw >> 112) & 0x8000;
    unsigned exponent = (unsigned)(raw >> 112) & 0x7fff;
    u128 fraction = raw & fraction_mask;
    if (exponent == 0x7fff) return (uint16_t)(sign | (fraction ? 0x7e00 : 0x7c00));
    if (!exponent) return (uint16_t)sign;
    int unbiased = (int)exponent - 16383;
    if (unbiased > 15) return (uint16_t)(sign | 0x7c00);
    u128 significand = ((u128)1 << 112) | fraction;
    if (unbiased < -14) return (uint16_t)(sign | (unsigned)rounded_right(significand, (unsigned)(88 - unbiased)));
    unsigned rounded = (unsigned)rounded_right(significand, 102);
    if (rounded == 2048) { rounded = 1024; ++unbiased; }
    if (unbiased > 15) return (uint16_t)(sign | 0x7c00);
    return (uint16_t)(sign | ((unsigned)(unbiased + 15) << 10) | (rounded - 1024));
}

static u128 quad_to_integer(u128 raw) {
    int exponent = (int)((raw >> 112) & 0x7fff) - 16383;
    if (exponent < 0) return 0;
    u128 significand = ((u128)1 << 112) | (raw & fraction_mask);
    u128 magnitude = exponent >= 112 ? significand << (unsigned)(exponent - 112) : significand >> (unsigned)(112 - exponent);
    return raw & sign_mask ? ~magnitude + 1 : magnitude;
}

static unsigned quad_nan(u128 raw) {
    return ((raw >> 112) & 0x7fff) == 0x7fff && (raw & fraction_mask) != 0;
}

static unsigned equivalent(unsigned which, u128 expected, u128 actual) {
    if (which == 0 && quad_nan(expected)) return quad_nan(actual);
    if (which == 3 && ((unsigned)expected & 0x7c00) == 0x7c00 && ((unsigned)expected & 0x03ff))
        return actual <= UINT16_MAX && ((unsigned)actual & 0x7c00) == 0x7c00 && ((unsigned)actual & 0x03ff);
    return actual == expected;
}

static int mismatch(unsigned which, unsigned iteration, const char *stage) {
    fprintf(stderr,"extended float conversion mismatch case=%u iteration=%u stage=%s fault=%u observation=%u\n",
            which, iteration, stage, fault, observations);
    return 1;
}

static int check(unsigned which, unsigned iteration, u128 input) {
    uint64_t live = (uint64_t)input ^ (uint64_t)(input >> 64) ^ UINT64_C(0x9e3779b97f4a7c15);
    uint64_t e1 = ~live + which, e2 = live * 33 + iteration;
    uint64_t e3 = live ^ ((uint64_t)iteration << 41), e4 = live + UINT64_C(0x5566778899aabbcc);
    u128 expected;
    switch (which) {
        case 0: expected = half_to_quad((uint16_t)input); break;
        case 1: expected = integer_to_quad(input,1); break;
        case 2: expected = integer_to_quad(input,0); break;
        case 3: expected = quad_to_half(input); break;
        case 4: case 5: expected = quad_to_integer(input); break;
        case 6: expected = integer_to_quad(sign_mask | 1,1); break;
        case 7: expected = integer_to_quad(~(u128)0,0); break;
        case 8: expected = input + rotate(input ^ e1,17) + input + (((u128)live<<64) | e4); break;
        default: expected = input ^ rotate(input,29) ^ e2; break;
    }
    uint64_t mixed = (((live ^ e1) + e2) ^ e3) + e4;
    uint8_t guarded[20];
    memset(guarded,0xa7,sizeof guarded);
    u128 actual = cases[which](input,live,e1,e2,e3,e4,guarded+1);
    if (fault == 1) actual ^= 1;
    if (fault == 2) guarded[1] ^= 1;
    if (fault == 3) guarded[17] ^= 1;
    if (!equivalent(which,expected,actual ^ input ^ mixed)) return mismatch(which,iteration,"return-live");
    memcpy(&actual,guarded+1,16);
    if (!equivalent(which,expected,actual)) return mismatch(which,iteration,"stored-bits");
    if (guarded[0] != 0xa7) return mismatch(which,iteration,"prefix-guard");
    for (unsigned i=17;i<sizeof guarded;++i)
        if (guarded[i] != 0xa7) return mismatch(which,iteration,"suffix-guard");
    ++observations;
    return 0;
}

static uint64_t random_word(void) {
    static uint64_t state = UINT64_C(0x983764ab1f20c5d9);
    state ^= state << 13; state ^= state >> 7; state ^= state << 17;
    return state;
}

int main(int argc,char **argv) {
    if (argc == 2) fault = (unsigned)strtoul(argv[1],0,10);
    if (argc > 2 || fault > 3) return 2;
    for (unsigned i=0;i<=UINT16_MAX;++i) {
        u128 raw = ((u128)random_word()<<64) | (random_word() & ~UINT64_C(0xffff)) | i;
        if (check(0,i,raw)) return 1;
    }
    for (unsigned which=1;which<10;++which) for (unsigned i=0;i<8192;++i) {
        u128 raw = ((u128)random_word()<<64) | random_word();
        if (which == 1 || which == 2) {
            if (i == 0) raw = 0;
            if (i == 1) raw = ~(u128)0;
            if (i == 2) raw = sign_mask;
            if (i == 3) raw = sign_mask-1;
            if (i >= 4 && i < 19) raw = ((u128)1<<127) | ((u128)1<<(i-4));
        }
        if (which == 3) {
            if (i % 4 == 0) raw = half_to_quad((uint16_t)(i*40503U));
            if (i % 4 == 1) {
                int exponent = (int)(i%47)-25;
                raw = (raw & (sign_mask | fraction_mask)) | ((u128)(16383+exponent)<<112);
            }
            if (i % 4 == 2) {
                raw = (raw & sign_mask) | ((u128)(16383+(int)(i%30)-15)<<112) |
                      ((u128)(i&1023)<<102) | ((u128)1<<101);
                raw += (u128)(i%3)-1;
            }
        }
        if (which == 4 || which == 5) {
            int exponent = (int)(i%128)-1;
            u128 sign = (which == 4 || exponent < 0) ? raw & sign_mask : 0;
            raw = sign | ((u128)(16383+exponent)<<112) | (raw & fraction_mask);
            if (i == 0) raw = which == 4 ? sign_mask | ((u128)(16383+127)<<112) : ((u128)(16383+127)<<112) | fraction_mask;
        }
        if (check(which,i,raw)) return 1;
    }
    if (observations != 139264) return mismatch(0,0,"count");
    puts("extended-float-conversion observations=139264 rounding=classes=wide=abi=live=stores=guards=preserved");
    return 0;
}
