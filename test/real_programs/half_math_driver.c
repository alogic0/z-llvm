#define _GNU_SOURCE
#include <stdint.h>
typedef uint64_t (*math_fn)(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
struct math_case {math_fn function;unsigned operation;};
extern uint64_t half_math_trunc(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_round(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_ceil(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_floor(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_log10(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_log2(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_log(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_exp2(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_exp(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_tan(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_cos(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_sin(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_sqrt(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_math_fma(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
static const struct math_case cases[]={
{half_math_trunc,0},
{half_math_round,1},
{half_math_ceil,2},
{half_math_floor,3},
{half_math_log10,4},
{half_math_log2,5},
{half_math_log,6},
{half_math_exp2,7},
{half_math_exp,8},
{half_math_tan,9},
{half_math_cos,10},
{half_math_sin,11},
{half_math_sqrt,12},
{half_math_fma,13},
};
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <errno.h>
#include <sys/mman.h>
#include <unistd.h>
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
__attribute__((noinline)) uint64_t half_math_clobber(uint64_t seed){
    uint64_t result=seed^key;
    __asm__ volatile(
        "xor %%eax,%%eax\n\txor %%ecx,%%ecx\n\txor %%edx,%%edx\n\t"
        "xor %%edi,%%edi\n\txor %%esi,%%esi\n\txor %%r8d,%%r8d\n\t"
        "xor %%r9d,%%r9d\n\txor %%r10d,%%r10d\n\txor %%r11d,%%r11d\n\t"
        "pxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1\n\tpxor %%xmm2,%%xmm2\n\t"
        "pxor %%xmm3,%%xmm3\n\tpxor %%xmm4,%%xmm4\n\tpxor %%xmm5,%%xmm5\n\t"
        "pxor %%xmm6,%%xmm6\n\tpxor %%xmm7,%%xmm7\n\tpxor %%xmm8,%%xmm8\n\t"
        "pxor %%xmm9,%%xmm9\n\tpxor %%xmm10,%%xmm10\n\tpxor %%xmm11,%%xmm11\n\t"
        "pxor %%xmm12,%%xmm12\n\tpxor %%xmm13,%%xmm13\n\tpxor %%xmm14,%%xmm14\n\tpxor %%xmm15,%%xmm15"
        :::"rax","rcx","rdx","rdi","rsi","r8","r9","r10","r11","xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7","xmm8","xmm9","xmm10","xmm11","xmm12","xmm13","xmm14","xmm15","cc","memory");return result;
}
static float widen(uint16_t raw){
    unsigned exponent=(raw>>10)&31,fraction=raw&1023;uint32_t bits=(uint32_t)(raw&32768)<<16;
    if(exponent==31)bits|=UINT32_C(0x7f800000)|(fraction<<13);
    else if(exponent)bits|=((exponent+112)<<23)|(fraction<<13);
    else if(fraction){unsigned top=31-__builtin_clz(fraction);bits|=((top+103)<<23)|((fraction-(1u<<top))<<(23-top));}
    float result;memcpy(&result,&bits,4);return result;
}
/* Independent integer round-to-nearest-even from a decoded IEEE significand. */
static uint16_t narrow(uint64_t raw,unsigned fraction_bits,unsigned exponent_bits,unsigned bias){
    unsigned sign=(unsigned)(raw>>(fraction_bits+exponent_bits))<<15;
    unsigned maximum=(1u<<exponent_bits)-1,exponent=(unsigned)(raw>>fraction_bits)&maximum;
    uint64_t fraction=raw&((UINT64_C(1)<<fraction_bits)-1);
    if(exponent==maximum)return (uint16_t)(sign|0x7c00|(fraction?0x200:0));
    uint64_t significand=fraction|(exponent?(UINT64_C(1)<<fraction_bits):0);
    if(!significand)return (uint16_t)sign;
    int power=(exponent?(int)exponent:1)-(int)bias-(int)fraction_bits;
    int highest=63-__builtin_clzll(significand),half_exponent=highest+power;
    if(half_exponent>15)return (uint16_t)(sign|0x7c00);
    int shift=(half_exponent>=-14?half_exponent-10:-24)-power;
    uint64_t rounded;
    if(shift<=0)rounded=significand<<-shift;
    else if(shift>=64)rounded=0;
    else {uint64_t remainder=significand&((UINT64_C(1)<<shift)-1),halfway=UINT64_C(1)<<(shift-1);rounded=significand>>shift;rounded+=remainder>halfway||(remainder==halfway&&(rounded&1));}
    if(half_exponent<-14)return (uint16_t)(sign|rounded);
    if(rounded==2048){rounded=1024;++half_exponent;}
    if(half_exponent>15)return (uint16_t)(sign|0x7c00);
    return (uint16_t)(sign|((half_exponent+15)<<10)|(rounded&1023));
}
__attribute__((noinline)) static float unary(unsigned operation,float a){
    switch(operation){case 0:return truncf(a);case 1:return roundf(a);case 2:return ceilf(a);case 3:return floorf(a);
    case 4:return log10f(a);case 5:return log2f(a);case 6:return logf(a);case 7:return exp2f(a);case 8:return expf(a);
    case 9:return tanf(a);case 10:return cosf(a);case 11:return sinf(a);case 12:{float r;__asm__("sqrtss %1,%0":"=x"(r):"x"(a));return r;}default:abort();}
}
static int nan_half(uint16_t bits){return (bits&0x7c00)==0x7c00&&(bits&1023);}
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"half math mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
static int check(uint8_t *left,uint8_t *right,uint8_t *third,unsigned which,unsigned row){
    uint16_t a=(uint16_t)row,b=(uint16_t)(row*40503u+17),c=(uint16_t)(row*25173u+0x8001);
    memcpy(left,&a,2);memcpy(right,&b,2);memcpy(third,&c,2);
    uint16_t expected;errno=0;
    if(cases[which].operation==13){double r=fma((double)widen(a),(double)widen(b),(double)widen(c));uint64_t bits;memcpy(&bits,&r,8);expected=narrow(bits,52,11,1023);}
    else{float r=unary(cases[which].operation,widen(a));uint32_t bits;memcpy(&bits,&r,4);expected=narrow(bits,23,8,127);}
    int expected_errno=errno;uint64_t live=((uint64_t)a<<32)^((uint64_t)b<<16)^c^row;uint8_t output[16];memset(output,0xa7,sizeof output);errno=0;
    uint64_t actual=cases[which].function(left,right,third,output+1,live);int actual_errno=errno;
    if(fault==1)actual^=1;if(fault==2)output[1]^=1;if(fault==3)output[3]^=1;
    uint16_t stored;memcpy(&stored,output+1,2);
    if(actual!=(live^key))return mismatch(which,row,"live");
    if(nan_half(expected)?!nan_half(stored):stored!=expected)return mismatch(which,row,"math-bits");
    if(actual_errno!=expected_errno)return mismatch(which,row,"errno");
    if(output[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=3;i<sizeof output;++i)if(output[i]!=0xa7)return mismatch(which,row,"suffix");
    if(memcmp(left,&a,2)||memcmp(right,&b,2)||memcmp(third,&c,2))return mismatch(which,row,"inputs-mutated");
    ++observations;return 0;
}
int main(int argc,char **argv){
    if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;long page=sysconf(_SC_PAGESIZE);if(page<4096)return 2;
    uint8_t *mapping=mmap(0,(size_t)page*6,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE)||mprotect(mapping+3*page,(size_t)page,PROT_NONE)||mprotect(mapping+5*page,(size_t)page,PROT_NONE))return 2;
    for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which)for(unsigned row=0;row<65536;++row)if(check(mapping+page-2,mapping+3*page-2,mapping+5*page-2,which,row))return 1;
    munmap(mapping,(size_t)page*6);printf("half-math observations=%u exhaustive=promotion=fma=rounding=errno=live=guards=preserved\n",observations);return observations==917504?0:2;
}
