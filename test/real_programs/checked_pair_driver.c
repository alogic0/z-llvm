#include <stdint.h>
#include <stdio.h>
typedef unsigned __int128 U;
typedef __int128 S;
typedef uint64_t (*Operation)(U, U, void *);
__attribute__((noinline)) uint64_t checked_pair_clobber(uint64_t low) {
    uint64_t result = low ^ UINT64_C(0x6a34d1fb823079ce);
    __asm__ volatile("xor %%eax,%%eax; xor %%edx,%%edx; xor %%ecx,%%ecx; xor %%edi,%%edi; xor %%esi,%%esi; xor %%r8d,%%r8d; xor %%r9d,%%r9d" ::: "rax", "rdx", "rcx", "rdi", "rsi", "r8", "r9", "cc");
    return result;
}
extern uint64_t checked_pair_uadd(U, U, void *);
extern uint64_t checked_pair_usub(U, U, void *);
extern uint64_t checked_pair_sadd(U, U, void *);
extern uint64_t checked_pair_ssub(U, U, void *);
extern uint64_t checked_pair_smul3(U, U, void *);
extern uint64_t checked_pair_umul3(U, U, void *);
extern uint64_t checked_pair_smul_billion(U, U, void *);
extern uint64_t checked_pair_umul_billion(U, U, void *);
static Operation operations[] = { checked_pair_uadd, checked_pair_usub, checked_pair_sadd, checked_pair_ssub, checked_pair_smul3, checked_pair_umul3, checked_pair_smul_billion, checked_pair_umul_billion };
static uint64_t next(uint64_t *s) { *s ^= *s << 13; *s ^= *s >> 7; *s ^= *s << 17; return *s; }
int main(void) {
    uint64_t state = UINT64_C(0xf304d19e657a2c8b);
    const U values[] = { 0, 1, 2, 3, ~(U)0, ~(U)1, (U)1<<127, ((U)1<<127)-1, (U)1<<64, ((U)1<<96)-1, (~(U)0)/3, (~(U)0)/1000000000 };
    unsigned observations = 0;
    for (unsigned which=0; which<8; ++which) for (unsigned i=0; i<1024; ++i) {
        U a = (U)next(&state)<<64; a |= next(&state);
        U b = (U)next(&state)<<64; b |= next(&state);
        if (i<144) { a=values[i/12]; b=values[i%12]; }
        U wrapped; S signed_wrapped; int overflow;
        switch (which) {
            case 0: overflow=__builtin_add_overflow(a, b, &wrapped); break;
            case 1: overflow=__builtin_sub_overflow(a, b, &wrapped); break;
            case 2: overflow=__builtin_add_overflow((S)a, (S)b, &signed_wrapped); wrapped=(U)signed_wrapped; break;
            case 3: overflow=__builtin_sub_overflow((S)a, (S)b, &signed_wrapped); wrapped=(U)signed_wrapped; break;
            case 4: overflow=__builtin_mul_overflow((S)a, (S)3, &signed_wrapped); wrapped=(U)signed_wrapped; break;
            case 5: overflow=__builtin_mul_overflow(a, (U)3, &wrapped); break;
            case 6: overflow=__builtin_mul_overflow((S)a, (S)1000000000, &signed_wrapped); wrapped=(U)signed_wrapped; break;
            case 7: overflow=__builtin_mul_overflow(a, (U)1000000000, &wrapped); break;
            default: return 99;
        }
        uint64_t out[5] = { UINT64_C(0xdeadbeefbeefdead), 0, 0, 0, UINT64_C(0xa5a55a5af0f00f0f) };
        uint64_t got=operations[which](a,b,out+1);
        uint64_t expected=(uint64_t)(wrapped>>64) ^ UINT64_C(0x6a34d1fb823079ce);
        if (got!=expected || out[1]!=(uint64_t)wrapped || out[2]!=(uint64_t)(wrapped>>64) || out[3]!=(unsigned)overflow ||
            out[0]!=UINT64_C(0xdeadbeefbeefdead) || out[4]!=UINT64_C(0xa5a55a5af0f00f0f)) {
            fprintf(stderr,"checked pair case=%u input=%u got=%llu expected=%llu flag=%llu expected_flag=%d\n",
                    which,i,(unsigned long long)got,(unsigned long long)expected,(unsigned long long)out[3],overflow);
            return 1;
        }
        ++observations;
    }
    printf("checked-pair observations=%u widths=128 overflow=checked calls=preserved\n",observations);
    return 0;
}
