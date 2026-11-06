#include <stdint.h>
#include <stdio.h>
typedef unsigned __int128 U;
typedef __int128 S;
typedef uint64_t (*Operation)(uint64_t, uint64_t, void *);
__attribute__((noinline)) uint64_t checked_scalar_clobber(uint64_t x) {
    uint64_t result = x ^ UINT64_C(0xa5b6c7d8e9f01234);
    __asm__ volatile("xor %%eax,%%eax; xor %%edx,%%edx; xor %%ecx,%%ecx; xor %%edi,%%edi; xor %%esi,%%esi; xor %%r8d,%%r8d; xor %%r9d,%%r9d" ::: "rax", "rdx", "rcx", "rdi", "rsi", "r8", "r9", "cc");
    return result;
}
extern uint64_t checked_scalar_33_uadd(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_33_usub(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_33_umul(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_33_sadd(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_33_ssub(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_33_smul(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_39_uadd(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_39_usub(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_39_umul(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_39_sadd(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_39_ssub(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_39_smul(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_63_uadd(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_63_usub(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_63_umul(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_63_sadd(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_63_ssub(uint64_t, uint64_t, void *);
extern uint64_t checked_scalar_63_smul(uint64_t, uint64_t, void *);
static Operation operations[3][6] = {
    { checked_scalar_33_uadd, checked_scalar_33_usub, checked_scalar_33_umul, checked_scalar_33_sadd, checked_scalar_33_ssub, checked_scalar_33_smul },
    { checked_scalar_39_uadd, checked_scalar_39_usub, checked_scalar_39_umul, checked_scalar_39_sadd, checked_scalar_39_ssub, checked_scalar_39_smul },
    { checked_scalar_63_uadd, checked_scalar_63_usub, checked_scalar_63_umul, checked_scalar_63_sadd, checked_scalar_63_ssub, checked_scalar_63_smul }
};
static uint64_t next(uint64_t *s) { *s ^= *s << 13; *s ^= *s >> 7; *s ^= *s << 17; return *s; }
int main(void) {
    uint64_t state = UINT64_C(0xf304d19e657a2c8b);
    const unsigned widths[] = { 33, 39, 63 };
    unsigned observations = 0;
    for (unsigned width=0; width<3; ++width) {
        unsigned bits=widths[width];
        uint64_t mask=(UINT64_C(1)<<bits)-1, sign=UINT64_C(1)<<(bits-1);
        const uint64_t values[]={0,1,2,3,mask,mask-1,sign,sign-1,sign+1,UINT64_MAX,UINT64_MAX-1,UINT64_C(0xdeadbeef12345678)};
        for (unsigned op=0; op<6; ++op) for (unsigned i=0; i<1024; ++i) {
            uint64_t a=next(&state), b=next(&state);
            if (i<144) { a=values[i/12]; b=values[i%12]; }
            U x=a&mask,y=b&mask,full;
            int overflow;
            if (op<3) {
                full=op==0 ? x+y : op==1 ? x-y : x*y;
                overflow=op==1 ? x<y : full>mask;
            } else {
                S sx=(S)(x^sign)-(S)sign, sy=(S)(y^sign)-(S)sign;
                S sf=op==3 ? sx+sy : op==4 ? sx-sy : sx*sy;
                full=(U)sf;
                overflow=sf < -(S)sign || sf >= (S)sign;
            }
            uint64_t wrapped=(uint64_t)full & mask;
            uint64_t out[4]={UINT64_C(0xfeedfacecafebeef),0,0,UINT64_C(0xdecafbad12345678)};
            uint64_t result=operations[width][op](a,b,out+1);
            uint64_t wanted=wrapped ^ UINT64_C(0xa5b6c7d8e9f01234) ^ a ^ b;
            if (result!=wanted || out[1]!=wrapped || out[2]!=(unsigned)overflow ||
                out[0]!=UINT64_C(0xfeedfacecafebeef) || out[3]!=UINT64_C(0xdecafbad12345678)) {
                fprintf(stderr,"checked scalar width=%u op=%u case=%u value=%llx expected=%llx flag=%llu expected_flag=%u result=%llx expected_result=%llx\n",bits,op,i,
                    (unsigned long long)out[1],(unsigned long long)wrapped,(unsigned long long)out[2],overflow,(unsigned long long)result,(unsigned long long)wanted);
                return 1;
            }
            ++observations;
        }
    }
    printf("checked-scalar observations=%u widths=33,39,63 overflow=checked calls=preserved\n",observations);
    return 0;
}
