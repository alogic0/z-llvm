#include <stdint.h>
#include <stdio.h>

typedef unsigned __int128 u128;
typedef __int128 s128;
typedef uint64_t (*Operation)(u128, u128, uint64_t, void *);

__attribute__((noinline)) uint64_t wide_clobber(uint64_t input) {
    uint64_t result = input ^ UINT64_C(0x123456789abcdef0);
    __asm__ volatile(
        "xor %%eax,%%eax; xor %%edx,%%edx; xor %%ecx,%%ecx;"
        "xor %%edi,%%edi; xor %%esi,%%esi; xor %%r8d,%%r8d; xor %%r9d,%%r9d"
        ::: "rax", "rdx", "rcx", "rdi", "rsi", "r8", "r9", "cc");
    return result;
}

extern uint64_t wide_65_add(u128, u128, uint64_t, void *);
extern uint64_t wide_65_sub(u128, u128, uint64_t, void *);
extern uint64_t wide_65_mul(u128, u128, uint64_t, void *);
extern uint64_t wide_65_and(u128, u128, uint64_t, void *);
extern uint64_t wide_65_xor(u128, u128, uint64_t, void *);
extern uint64_t wide_65_or_literal(u128, u128, uint64_t, void *);
extern uint64_t wide_65_shl(u128, u128, uint64_t, void *);
extern uint64_t wide_65_shl_top(u128, u128, uint64_t, void *);
extern uint64_t wide_65_lshr(u128, u128, uint64_t, void *);
extern uint64_t wide_65_lshr_top(u128, u128, uint64_t, void *);
extern uint64_t wide_65_ashr(u128, u128, uint64_t, void *);
extern uint64_t wide_65_ashr_top(u128, u128, uint64_t, void *);
extern uint64_t wide_65_sdiv(u128, u128, uint64_t, void *);
extern uint64_t wide_65_srem(u128, u128, uint64_t, void *);
extern uint64_t wide_65_udiv(u128, u128, uint64_t, void *);
extern uint64_t wide_65_urem(u128, u128, uint64_t, void *);
extern uint64_t wide_65_zext(u128, u128, uint64_t, void *);
extern uint64_t wide_65_sext(u128, u128, uint64_t, void *);
extern uint64_t wide_65_slt(u128, u128, uint64_t, void *);
extern uint64_t wide_65_select(u128, u128, uint64_t, void *);
extern uint64_t wide_65_uadd_checked(u128, u128, uint64_t, void *);
extern uint64_t wide_65_usub_checked(u128, u128, uint64_t, void *);
extern uint64_t wide_65_sadd_checked(u128, u128, uint64_t, void *);
extern uint64_t wide_65_ssub_checked(u128, u128, uint64_t, void *);
extern uint64_t wide_96_add(u128, u128, uint64_t, void *);
extern uint64_t wide_96_sub(u128, u128, uint64_t, void *);
extern uint64_t wide_96_mul(u128, u128, uint64_t, void *);
extern uint64_t wide_96_and(u128, u128, uint64_t, void *);
extern uint64_t wide_96_xor(u128, u128, uint64_t, void *);
extern uint64_t wide_96_or_literal(u128, u128, uint64_t, void *);
extern uint64_t wide_96_shl(u128, u128, uint64_t, void *);
extern uint64_t wide_96_shl_top(u128, u128, uint64_t, void *);
extern uint64_t wide_96_lshr(u128, u128, uint64_t, void *);
extern uint64_t wide_96_lshr_top(u128, u128, uint64_t, void *);
extern uint64_t wide_96_ashr(u128, u128, uint64_t, void *);
extern uint64_t wide_96_ashr_top(u128, u128, uint64_t, void *);
extern uint64_t wide_96_sdiv(u128, u128, uint64_t, void *);
extern uint64_t wide_96_srem(u128, u128, uint64_t, void *);
extern uint64_t wide_96_udiv(u128, u128, uint64_t, void *);
extern uint64_t wide_96_urem(u128, u128, uint64_t, void *);
extern uint64_t wide_96_zext(u128, u128, uint64_t, void *);
extern uint64_t wide_96_sext(u128, u128, uint64_t, void *);
extern uint64_t wide_96_slt(u128, u128, uint64_t, void *);
extern uint64_t wide_96_select(u128, u128, uint64_t, void *);
extern uint64_t wide_96_uadd_checked(u128, u128, uint64_t, void *);
extern uint64_t wide_96_usub_checked(u128, u128, uint64_t, void *);
extern uint64_t wide_96_sadd_checked(u128, u128, uint64_t, void *);
extern uint64_t wide_96_ssub_checked(u128, u128, uint64_t, void *);

enum Kind { ADD, SUB, MUL, AND, XOR, OR_LITERAL, SHL, SHL_TOP, LSHR, LSHR_TOP, ASHR, ASHR_TOP, SDIV, SREM, UDIV, UREM, ZEXT, SEXT, SLT, SELECT, UADD_CHECKED, USUB_CHECKED, SADD_CHECKED, SSUB_CHECKED };
struct Case { const char *name; Operation run; unsigned width; enum Kind kind; };
static const struct Case cases[] = {
    { "wide_65_add", wide_65_add, 65, ADD },
    { "wide_65_sub", wide_65_sub, 65, SUB },
    { "wide_65_mul", wide_65_mul, 65, MUL },
    { "wide_65_and", wide_65_and, 65, AND },
    { "wide_65_xor", wide_65_xor, 65, XOR },
    { "wide_65_or_literal", wide_65_or_literal, 65, OR_LITERAL },
    { "wide_65_shl", wide_65_shl, 65, SHL },
    { "wide_65_shl_top", wide_65_shl_top, 65, SHL_TOP },
    { "wide_65_lshr", wide_65_lshr, 65, LSHR },
    { "wide_65_lshr_top", wide_65_lshr_top, 65, LSHR_TOP },
    { "wide_65_ashr", wide_65_ashr, 65, ASHR },
    { "wide_65_ashr_top", wide_65_ashr_top, 65, ASHR_TOP },
    { "wide_65_sdiv", wide_65_sdiv, 65, SDIV },
    { "wide_65_srem", wide_65_srem, 65, SREM },
    { "wide_65_udiv", wide_65_udiv, 65, UDIV },
    { "wide_65_urem", wide_65_urem, 65, UREM },
    { "wide_65_zext", wide_65_zext, 65, ZEXT },
    { "wide_65_sext", wide_65_sext, 65, SEXT },
    { "wide_65_slt", wide_65_slt, 65, SLT },
    { "wide_65_select", wide_65_select, 65, SELECT },
    { "wide_65_uadd_checked", wide_65_uadd_checked, 65, UADD_CHECKED },
    { "wide_65_usub_checked", wide_65_usub_checked, 65, USUB_CHECKED },
    { "wide_65_sadd_checked", wide_65_sadd_checked, 65, SADD_CHECKED },
    { "wide_65_ssub_checked", wide_65_ssub_checked, 65, SSUB_CHECKED },
    { "wide_96_add", wide_96_add, 96, ADD },
    { "wide_96_sub", wide_96_sub, 96, SUB },
    { "wide_96_mul", wide_96_mul, 96, MUL },
    { "wide_96_and", wide_96_and, 96, AND },
    { "wide_96_xor", wide_96_xor, 96, XOR },
    { "wide_96_or_literal", wide_96_or_literal, 96, OR_LITERAL },
    { "wide_96_shl", wide_96_shl, 96, SHL },
    { "wide_96_shl_top", wide_96_shl_top, 96, SHL_TOP },
    { "wide_96_lshr", wide_96_lshr, 96, LSHR },
    { "wide_96_lshr_top", wide_96_lshr_top, 96, LSHR_TOP },
    { "wide_96_ashr", wide_96_ashr, 96, ASHR },
    { "wide_96_ashr_top", wide_96_ashr_top, 96, ASHR_TOP },
    { "wide_96_sdiv", wide_96_sdiv, 96, SDIV },
    { "wide_96_srem", wide_96_srem, 96, SREM },
    { "wide_96_udiv", wide_96_udiv, 96, UDIV },
    { "wide_96_urem", wide_96_urem, 96, UREM },
    { "wide_96_zext", wide_96_zext, 96, ZEXT },
    { "wide_96_sext", wide_96_sext, 96, SEXT },
    { "wide_96_slt", wide_96_slt, 96, SLT },
    { "wide_96_select", wide_96_select, 96, SELECT },
    { "wide_96_uadd_checked", wide_96_uadd_checked, 96, UADD_CHECKED },
    { "wide_96_usub_checked", wide_96_usub_checked, 96, USUB_CHECKED },
    { "wide_96_sadd_checked", wide_96_sadd_checked, 96, SADD_CHECKED },
    { "wide_96_ssub_checked", wide_96_ssub_checked, 96, SSUB_CHECKED },
};

static u128 expected(enum Kind kind, unsigned width, u128 a, u128 b, uint64_t *overflow) {
    const u128 mask = ((u128)1 << width) - 1;
    const u128 sign = (u128)1 << (width - 1);
    a &= mask;
    b &= mask;
    const s128 sa = (s128)(a ^ sign) - (s128)sign;
    const s128 sb = (s128)(b ^ sign) - (s128)sign;
    const unsigned count = b & 63;
    *overflow = 0;
    u128 result;
    switch (kind) {
    case ADD: result = a + b; break;
    case SUB: result = a - b; break;
    case MUL: result = a * b; break;
    case AND: result = a & b; break;
    case XOR: result = a ^ b; break;
    case OR_LITERAL: result = a | ((u128)1 << 63) | 3; break;
    case SHL: result = a << count; break;
    case SHL_TOP: result = a << (width - 1); break;
    case LSHR: result = a >> count; break;
    case LSHR_TOP: result = a >> (width - 1); break;
    case ASHR: result = (u128)(sa >> count); break;
    case ASHR_TOP: result = (u128)(sa >> (width - 1)); break;
    case SDIV: result = (u128)(sa / 3); break;
    case SREM: result = (u128)(sa % 3); break;
    case UDIV: result = a / 3; break;
    case UREM: result = a % 3; break;
    case ZEXT: result = (uint8_t)a; break;
    case SEXT: result = (u128)(s128)(int8_t)a; break;
    case SLT: result = sa < sb; break;
    case SELECT: result = (b & 1) ? a : b; break;
    case UADD_CHECKED:
        result = a + b;
        *overflow = result > mask;
        break;
    case USUB_CHECKED:
        result = a - b;
        *overflow = a < b;
        break;
    case SADD_CHECKED: {
        const s128 full = sa + sb;
        result = (u128)full;
        *overflow = full < -(s128)sign || full >= (s128)sign;
        break;
    }
    case SSUB_CHECKED: {
        const s128 full = sa - sb;
        result = (u128)full;
        *overflow = full < -(s128)sign || full >= (s128)sign;
        break;
    }
    default: __builtin_trap();
    }
    return result & mask;
}

int main(void) {
    unsigned observations = 0;
    uint64_t state = 0x12345678;
    for (unsigned c = 0; c < sizeof(cases) / sizeof(cases[0]); ++c) {
        const struct Case *test = &cases[c];
        for (unsigned i = 0; i < 256; ++i) {
            state = state * UINT64_C(6364136223846793005) + UINT64_C(1442695040888963407);
            u128 a = ((u128)(state ^ 0xaabbccdd) << 64) | state;
            u128 b = ((u128)(state * 3) << 64) | (i % 64);
            const u128 sign = (u128)1 << (test->width - 1);
            switch (i % 8) {
            case 0: a = 0; break;
            case 1: a = 1; break;
            case 2: a = sign - 1; break;
            case 3: a = sign; break;
            case 4: a = sign + 1; break;
            case 5: a = ~(u128)0; break;
            case 6: a = ~(u128)1; break;
            }
            if (i % 16 == 0) b = 1;
            if (i % 16 == 1) b = sign - 1;
            if (i % 16 == 2) b = sign;
            if (i % 16 == 3) b = ~(u128)0;
            struct { uint64_t before, lo, hi, overflow, after; } output = {111, 0, 0, 999, 222};
            const uint64_t live = state ^ 0x87654321u;
            uint64_t overflow;
            const u128 value = expected(test->kind, test->width, a, b, &overflow);
            const uint64_t result = test->run(a, b, live, &output.lo);
            const uint64_t return_value = ((uint64_t)value + (uint64_t)(value >> 64)) ^
                (live ^ UINT64_C(0x123456789abcdef0));
            if (output.before != 111 || output.after != 222 ||
                output.lo != (uint64_t)value || output.hi != (uint64_t)(value >> 64) ||
                output.overflow != overflow || result != return_value) {
                fprintf(stderr, "%s case=%u result=%016llx:%016llx overflow=%llu expected=%016llx:%016llx overflow=%llu\n",
                    test->name, i, (unsigned long long)output.hi, (unsigned long long)output.lo,
                    (unsigned long long)output.overflow, (unsigned long long)(value >> 64),
                    (unsigned long long)value, (unsigned long long)overflow);
                return 1;
            }
            ++observations;
        }
    }
    printf("wide-integer observations=%u widths=65,96 live=preserved overflow=checked\n", observations);
    return 0;
}
