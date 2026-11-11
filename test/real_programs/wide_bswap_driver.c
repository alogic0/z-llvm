#define _GNU_SOURCE
#include <stdint.h>
typedef unsigned __int128 u128;
typedef u128 (*swap_fn)(u128,uint8_t*,uint64_t);
struct swap_case {swap_fn function;unsigned width,literal;};
extern u128 wide_bswap_80_argument(u128,uint8_t*,uint64_t);
extern u128 wide_bswap_80_literal(u128,uint8_t*,uint64_t);
extern u128 wide_bswap_96_argument(u128,uint8_t*,uint64_t);
extern u128 wide_bswap_96_literal(u128,uint8_t*,uint64_t);
extern u128 wide_bswap_112_argument(u128,uint8_t*,uint64_t);
extern u128 wide_bswap_112_literal(u128,uint8_t*,uint64_t);
extern u128 wide_bswap_128_argument(u128,uint8_t*,uint64_t);
extern u128 wide_bswap_128_literal(u128,uint8_t*,uint64_t);
static const struct swap_case cases[]={
{wide_bswap_80_argument,80,0},
{wide_bswap_80_literal,80,1},
{wide_bswap_96_argument,96,0},
{wide_bswap_96_literal,96,1},
{wide_bswap_112_argument,112,0},
{wide_bswap_112_literal,112,1},
{wide_bswap_128_argument,128,0},
{wide_bswap_128_literal,128,1},
};
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static uint64_t random_word(void){static uint64_t s=UINT64_C(0x7123456789abcdef);s^=s<<13;s^=s>>7;s^=s<<17;return s;}
__attribute__((noinline)) uint64_t wide_bswap_clobber(uint64_t seed){
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
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"wide bswap mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
static int check(unsigned which,unsigned row){
    const struct swap_case *test=&cases[which];u128 mask=test->width==128?~(u128)0:((u128)1<<test->width)-1;
    u128 raw=((u128)random_word()<<64)|random_word();if(row<128)raw=(u128)1<<row;else if(row<256)raw=~((u128)1<<(row-128));else if(row==256)raw=0;else if(row==257)raw=~(u128)0;
    u128 fixed=((u128)UINT64_C(0xfedcba9876543210)<<64)|UINT64_C(0x0123456789abcdef);
    u128 value=(test->literal?fixed:raw)&mask,expected=0;
    for(unsigned byte=0;byte<test->width/8;++byte)expected=(expected<<8)|((value>>(byte*8))&255);
    uint64_t live=(uint64_t)raw^(uint64_t)(raw>>64)^row;
    uint8_t out[32];memset(out,0xa7,sizeof out);u128 actual=test->function(raw,out+1,live);
    if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[17]^=1;
    u128 stored;memcpy(&stored,out+1,16);
    if(actual!=(expected^(live^key))||stored!=expected)return mismatch(which,row,"bytes-live");
    if(out[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=17;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"suffix");
    ++observations;return 0;
}
int main(int argc,char **argv){
    if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;
    for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which)for(unsigned row=0;row<8192;++row)if(check(which,row))return 1;
    if(observations!=65536)return mismatch(0,0,"count");
    puts("wide-bswap observations=65536 bytes=widths=literal=live=guards=preserved");return 0;
}
