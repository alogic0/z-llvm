#define _GNU_SOURCE
#include <stdint.h>
typedef unsigned __int128 u128;
typedef u128 (*to_fn)(u128,uint8_t*,uint64_t);
typedef u128 (*from_fn)(const uint8_t*,uint8_t*,uint64_t);
struct to_case {to_fn function;unsigned width,sign,literal;};
struct from_case {from_fn function;unsigned format,width,sign;};
extern u128 scalar_integer_to_quad_1_0_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_1_1_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_8_0_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_8_1_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_16_0_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_16_1_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_32_0_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_32_1_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_52_0_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_52_1_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_64_0_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_64_1_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_65_0_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_65_1_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_80_0_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_80_1_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_113_0_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_113_1_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_127_0_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_127_1_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_128_0_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_128_1_0(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_128_0_1(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_to_quad_128_1_1(u128,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_1_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_1_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_8_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_8_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_16_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_16_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_32_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_32_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_52_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_52_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_64_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_64_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_65_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_65_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_80_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_80_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_113_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_113_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_127_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_127_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_128_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_0_128_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_1_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_1_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_8_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_8_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_16_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_16_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_32_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_32_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_52_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_52_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_64_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_64_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_65_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_65_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_80_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_80_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_113_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_113_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_127_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_127_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_128_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_1_128_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_1_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_1_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_8_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_8_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_16_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_16_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_32_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_32_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_52_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_52_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_64_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_64_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_65_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_65_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_80_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_80_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_113_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_113_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_127_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_127_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_128_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_2_128_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_1_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_1_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_8_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_8_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_16_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_16_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_32_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_32_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_52_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_52_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_64_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_64_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_65_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_65_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_80_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_80_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_113_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_113_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_127_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_127_1(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_128_0(const uint8_t*,uint8_t*,uint64_t);
extern u128 scalar_integer_from_3_128_1(const uint8_t*,uint8_t*,uint64_t);
static const struct to_case to_cases[]={
{scalar_integer_to_quad_1_0_0,1,0,0},
{scalar_integer_to_quad_1_1_0,1,1,0},
{scalar_integer_to_quad_8_0_0,8,0,0},
{scalar_integer_to_quad_8_1_0,8,1,0},
{scalar_integer_to_quad_16_0_0,16,0,0},
{scalar_integer_to_quad_16_1_0,16,1,0},
{scalar_integer_to_quad_32_0_0,32,0,0},
{scalar_integer_to_quad_32_1_0,32,1,0},
{scalar_integer_to_quad_52_0_0,52,0,0},
{scalar_integer_to_quad_52_1_0,52,1,0},
{scalar_integer_to_quad_64_0_0,64,0,0},
{scalar_integer_to_quad_64_1_0,64,1,0},
{scalar_integer_to_quad_65_0_0,65,0,0},
{scalar_integer_to_quad_65_1_0,65,1,0},
{scalar_integer_to_quad_80_0_0,80,0,0},
{scalar_integer_to_quad_80_1_0,80,1,0},
{scalar_integer_to_quad_113_0_0,113,0,0},
{scalar_integer_to_quad_113_1_0,113,1,0},
{scalar_integer_to_quad_127_0_0,127,0,0},
{scalar_integer_to_quad_127_1_0,127,1,0},
{scalar_integer_to_quad_128_0_0,128,0,0},
{scalar_integer_to_quad_128_1_0,128,1,0},
{scalar_integer_to_quad_128_0_1,128,0,1},
{scalar_integer_to_quad_128_1_1,128,1,1},
};
static const struct from_case from_cases[]={
{scalar_integer_from_0_1_0,0,1,0},
{scalar_integer_from_0_1_1,0,1,1},
{scalar_integer_from_0_8_0,0,8,0},
{scalar_integer_from_0_8_1,0,8,1},
{scalar_integer_from_0_16_0,0,16,0},
{scalar_integer_from_0_16_1,0,16,1},
{scalar_integer_from_0_32_0,0,32,0},
{scalar_integer_from_0_32_1,0,32,1},
{scalar_integer_from_0_52_0,0,52,0},
{scalar_integer_from_0_52_1,0,52,1},
{scalar_integer_from_0_64_0,0,64,0},
{scalar_integer_from_0_64_1,0,64,1},
{scalar_integer_from_0_65_0,0,65,0},
{scalar_integer_from_0_65_1,0,65,1},
{scalar_integer_from_0_80_0,0,80,0},
{scalar_integer_from_0_80_1,0,80,1},
{scalar_integer_from_0_113_0,0,113,0},
{scalar_integer_from_0_113_1,0,113,1},
{scalar_integer_from_0_127_0,0,127,0},
{scalar_integer_from_0_127_1,0,127,1},
{scalar_integer_from_0_128_0,0,128,0},
{scalar_integer_from_0_128_1,0,128,1},
{scalar_integer_from_1_1_0,1,1,0},
{scalar_integer_from_1_1_1,1,1,1},
{scalar_integer_from_1_8_0,1,8,0},
{scalar_integer_from_1_8_1,1,8,1},
{scalar_integer_from_1_16_0,1,16,0},
{scalar_integer_from_1_16_1,1,16,1},
{scalar_integer_from_1_32_0,1,32,0},
{scalar_integer_from_1_32_1,1,32,1},
{scalar_integer_from_1_52_0,1,52,0},
{scalar_integer_from_1_52_1,1,52,1},
{scalar_integer_from_1_64_0,1,64,0},
{scalar_integer_from_1_64_1,1,64,1},
{scalar_integer_from_1_65_0,1,65,0},
{scalar_integer_from_1_65_1,1,65,1},
{scalar_integer_from_1_80_0,1,80,0},
{scalar_integer_from_1_80_1,1,80,1},
{scalar_integer_from_1_113_0,1,113,0},
{scalar_integer_from_1_113_1,1,113,1},
{scalar_integer_from_1_127_0,1,127,0},
{scalar_integer_from_1_127_1,1,127,1},
{scalar_integer_from_1_128_0,1,128,0},
{scalar_integer_from_1_128_1,1,128,1},
{scalar_integer_from_2_1_0,2,1,0},
{scalar_integer_from_2_1_1,2,1,1},
{scalar_integer_from_2_8_0,2,8,0},
{scalar_integer_from_2_8_1,2,8,1},
{scalar_integer_from_2_16_0,2,16,0},
{scalar_integer_from_2_16_1,2,16,1},
{scalar_integer_from_2_32_0,2,32,0},
{scalar_integer_from_2_32_1,2,32,1},
{scalar_integer_from_2_52_0,2,52,0},
{scalar_integer_from_2_52_1,2,52,1},
{scalar_integer_from_2_64_0,2,64,0},
{scalar_integer_from_2_64_1,2,64,1},
{scalar_integer_from_2_65_0,2,65,0},
{scalar_integer_from_2_65_1,2,65,1},
{scalar_integer_from_2_80_0,2,80,0},
{scalar_integer_from_2_80_1,2,80,1},
{scalar_integer_from_2_113_0,2,113,0},
{scalar_integer_from_2_113_1,2,113,1},
{scalar_integer_from_2_127_0,2,127,0},
{scalar_integer_from_2_127_1,2,127,1},
{scalar_integer_from_2_128_0,2,128,0},
{scalar_integer_from_2_128_1,2,128,1},
{scalar_integer_from_3_1_0,3,1,0},
{scalar_integer_from_3_1_1,3,1,1},
{scalar_integer_from_3_8_0,3,8,0},
{scalar_integer_from_3_8_1,3,8,1},
{scalar_integer_from_3_16_0,3,16,0},
{scalar_integer_from_3_16_1,3,16,1},
{scalar_integer_from_3_32_0,3,32,0},
{scalar_integer_from_3_32_1,3,32,1},
{scalar_integer_from_3_52_0,3,52,0},
{scalar_integer_from_3_52_1,3,52,1},
{scalar_integer_from_3_64_0,3,64,0},
{scalar_integer_from_3_64_1,3,64,1},
{scalar_integer_from_3_65_0,3,65,0},
{scalar_integer_from_3_65_1,3,65,1},
{scalar_integer_from_3_80_0,3,80,0},
{scalar_integer_from_3_80_1,3,80,1},
{scalar_integer_from_3_113_0,3,113,0},
{scalar_integer_from_3_113_1,3,113,1},
{scalar_integer_from_3_127_0,3,127,0},
{scalar_integer_from_3_127_1,3,127,1},
{scalar_integer_from_3_128_0,3,128,0},
{scalar_integer_from_3_128_1,3,128,1},
};
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static uint64_t random_word(void){static uint64_t s=UINT64_C(0x4123456789abcdef);s^=s<<13;s^=s>>7;s^=s<<17;return s;}
static u128 mask(unsigned width){return width==128?~(u128)0:((u128)1<<width)-1;}
static u128 read_bits(const uint8_t *p,unsigned n){u128 v=0;for(unsigned i=0;i<n;++i)v|=(u128)p[i]<<(8*i);return v;}
static void write_bits(uint8_t *p,u128 v,unsigned n){for(unsigned i=0;i<n;++i)p[i]=(uint8_t)(v>>(8*i));}
__attribute__((noinline)) uint64_t scalar_integer_clobber(uint64_t seed){
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
struct format {unsigned size,fraction,exponent,bias;};
static const struct format formats[]={{2,10,5,15},{4,23,8,127},{8,52,11,1023},{16,112,15,16383}};
/* Decode the exact dyadic value and truncate with integer arithmetic. Only
   source casts with a representable mathematical integer are executed. */
static int float_integer(u128 raw,unsigned format,unsigned width,unsigned sign,u128 *answer){
    const struct format *f=&formats[format];unsigned negative=(unsigned)((raw>>(f->size*8-1))&1);
    unsigned exponent=(unsigned)((raw>>f->fraction)&mask(f->exponent));
    if(exponent==(unsigned)mask(f->exponent))return 0;
    u128 significand=raw&mask(f->fraction);if(exponent)significand|=(u128)1<<f->fraction;
    int top=(int)(exponent?exponent:1)-(int)f->bias;if(top>127)return 0;
    u128 magnitude=top<0?0:top>=(int)f->fraction?significand<<(top-f->fraction):significand>>(f->fraction-top);
    if(sign){u128 limit=(u128)1<<(width-1);if(negative?magnitude>limit:magnitude>=limit)return 0;}
    else if((negative&&magnitude)||(width<128&&magnitude>mask(width)))return 0;
    *answer=(negative?-magnitude:magnitude)&mask(width);return 1;
}
/* A113-bit significand is rounded once with ties to even. */
static u128 integer_quad(u128 raw,unsigned width,unsigned sign){
    u128 bits=raw&mask(width);unsigned negative=sign&&(unsigned)((bits>>(width-1))&1);
    u128 magnitude=negative?((~bits+1)&mask(width)):bits;if(!magnitude)return 0;
    unsigned top=0;for(u128 scan=magnitude;scan>>=1;)++top;unsigned exponent=16383+top;u128 significand;
    if(top<=112)significand=magnitude<<(112-top);else{unsigned shift=top-112;significand=magnitude>>shift;
        u128 rest=magnitude&mask(shift),halfway=(u128)1<<(shift-1);
        if(rest>halfway||(rest==halfway&&(significand&1)))++significand;
        if(significand==((u128)1<<113)){significand>>=1;++exponent;}}
    return ((u128)negative<<127)|((u128)exponent<<112)|(significand&mask(112));
}
static u128 input_float(unsigned format,unsigned width,unsigned sign,unsigned row,u128 *answer){
    const struct format *f=&formats[format];u128 sign_bit=(u128)1<<(f->size*8-1),raw;
    for(unsigned attempt=0;;++attempt){
        int top=(int)(random_word()%(width+70))-68;unsigned negative=(unsigned)(random_word()&1);
        int exponent=(int)f->bias+top;u128 fraction=(((u128)random_word()<<64)|random_word())&mask(f->fraction);
        raw=exponent<=0?fraction:exponent>=(int)mask(f->exponent)?0:((u128)(unsigned)exponent<<f->fraction)|fraction;
        raw|=negative?sign_bit:0;
        if(!attempt){
            u128 one=(u128)f->bias<<f->fraction;
            switch(row){case 0:raw=0;break;case 1:raw=sign_bit;break;case 2:raw=1;break;case 3:raw=sign_bit|1;break;
            case 4:raw=(u128)(f->bias-1)<<f->fraction;break;case 5:raw=sign_bit|((u128)(f->bias-1)<<f->fraction);break;
            case 6:raw=one;break;case 7:raw=sign_bit|one;break;
            case 8:case 9:case 10:case 11:case 12:case 13:{unsigned power=(row<12?width-1:width)+f->bias;
                if(power<(unsigned)mask(f->exponent)){raw=(u128)power<<f->fraction;if(row==10||row==11||row==13)--raw;if(row==9||row==11)raw|=sign_bit;}break;}
            case 14:raw=0x155;break;case 15:raw=sign_bit|0x155;break;
            case 16:case 17:raw=((mask(f->exponent)-1)<<f->fraction)|mask(f->fraction);if(row==17)raw|=sign_bit;break;
            case 18:case 19:raw=mask(f->fraction);if(row==19)raw|=sign_bit;break;default:break;}
        }
        if(float_integer(raw,format,width,sign,answer))return raw;
    }
}
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"scalar integer mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
static int check_to(unsigned which,unsigned row){
    const struct to_case *test=&to_cases[which];u128 raw=((u128)random_word()<<64)|random_word();
    if(row<128)raw=(u128)1<<row;else if(row<256)raw=~((u128)1<<(row-128));else if(row==256)raw=0;else if(row==257)raw=~(u128)0;
    u128 fixed=((u128)UINT64_C(0xfedcba9876543210)<<64)|UINT64_C(0x0123456789abcdef);
    u128 expected=integer_quad(test->literal?fixed:raw,test->width,test->sign);uint64_t live=(uint64_t)raw^(uint64_t)(raw>>64)^row;
    uint8_t out[32];memset(out,0xa7,sizeof out);u128 actual=test->function(raw,out+1,live);
    if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[17]^=1;
    if(actual!=(raw^(live^key))||read_bits(out+1,16)!=expected)return mismatch(which,row,"to-rounding-live");
    if(out[0]!=0xa7)return mismatch(which,row,"to-prefix");for(unsigned i=17;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"to-suffix");++observations;return 0;
}
static int check_from(uint8_t *input,unsigned which,unsigned row){
    const struct from_case *test=&from_cases[which];unsigned size=formats[test->format].size;u128 expected,raw=input_float(test->format,test->width,test->sign,row,&expected);
    write_bits(input,raw,size);uint8_t before[16];memcpy(before,input,size);uint64_t live=(uint64_t)raw^(uint64_t)(raw>>64)^row;
    uint8_t out[32];memset(out,0xa7,sizeof out);u128 actual=test->function(input,out+1,live);
    if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[17]^=1;
    if(actual!=(expected^(live^key))||read_bits(out+1,16)!=expected)return mismatch(24+which,row,"from-truncation-live");
    if(out[0]!=0xa7)return mismatch(24+which,row,"from-prefix");for(unsigned i=17;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(24+which,row,"from-suffix");
    if(memcmp(before,input,size))return mismatch(24+which,row,"input-mutated");++observations;return 0;
}
int main(int argc,char **argv){
    if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;long page=sysconf(_SC_PAGESIZE);if(page<4096)return 2;
    uint8_t *mapping=mmap(0,(size_t)page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE))return 2;
    for(unsigned which=0;which<sizeof to_cases/sizeof to_cases[0];++which)for(unsigned row=0;row<4096;++row)if(check_to(which,row))return 1;
    for(unsigned which=0;which<sizeof from_cases/sizeof from_cases[0];++which)for(unsigned row=0;row<4096;++row)if(check_from(mapping+page-formats[from_cases[which].format].size,which,row))return 1;
    if(observations!=458752)return mismatch(0,0,"count");if(munmap(mapping,(size_t)page*2))return 2;
    puts("scalar-integer observations=458752 formats=widths=rounding=truncation=literal=live=guards=preserved");return 0;
}
