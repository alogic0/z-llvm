#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef unsigned __int128 u128;
extern u128 integer_boundaries_umul(u128,u128,uint8_t*,uint64_t);
extern u128 integer_boundaries_smul(u128,u128,uint8_t*,uint64_t);
extern uint64_t integer_boundaries_target(const uint8_t*,uint64_t,uint8_t*,uint64_t);
extern uint64_t integer_boundaries_memset(uint8_t*,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_boundaries_memset_constant(uint8_t*,uint64_t,uint64_t,uint64_t);
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static uint64_t random_word(void){static uint64_t s=UINT64_C(0x9153456789abcdef);s^=s<<13;s^=s>>7;s^=s<<17;return s;}
__attribute__((noinline)) uint64_t integer_boundaries_clobber(uint64_t seed){
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
uint16_t target_bytes(const uint8_t*,uint16_t) __asm__("zig.target.intByteSize");
__attribute__((noinline)) uint16_t target_bytes(const uint8_t *context,uint16_t bits){return (uint16_t)((((uint32_t)bits+context[0]*257u+7)/8)^(context[0]<<8));}
static void product(u128 a,u128 b,uint32_t out[8]){
    memset(out,0,32);
    for(unsigned i=0;i<4;++i){uint64_t carry=0;for(unsigned j=0;j<4;++j){uint64_t value=(uint64_t)(uint32_t)(a>>(32*i))*(uint32_t)(b>>(32*j))+out[i+j]+carry;out[i+j]=(uint32_t)value;carry=value>>32;}out[i+4]=(uint32_t)carry;}
}
static u128 low(const uint32_t words[8]){u128 value=0;for(unsigned i=0;i<4;++i)value|=(u128)words[i]<<(32*i);return value;}
static int upper(const uint32_t words[8]){return words[4]||words[5]||words[6]||words[7];}
static u128 input(unsigned row){static const u128 values[]={0,1,2,UINT64_MAX,(u128)1<<64,((u128)1<<64)+1,(u128)1<<127,~(u128)0-1,~(u128)0};return row<81?values[row%9]:((u128)random_word()<<64)|random_word();}
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"integer boundaries mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
static int check(unsigned which,unsigned row){
    u128 a=input(row),b=row<81?input(row/9):input(row+1);uint64_t live=random_word();uint8_t out[40];memset(out,0xa7,sizeof out);
    if(which<2){uint32_t words[8];product(a,b,words);u128 expected=low(words);int overflow=upper(words);
        if(which){int negative=(int)(a>>127)^(int)(b>>127);u128 magnitude_a=a>>127?(~a+1):a,magnitude_b=b>>127?(~b+1):b;uint32_t magnitude[8];product(magnitude_a,magnitude_b,magnitude);u128 limit=((u128)1<<127)-(negative?0:1);overflow=upper(magnitude)||low(magnitude)>limit;}
        u128 actual=which?integer_boundaries_smul(a,b,out+1,live):integer_boundaries_umul(a,b,out+1,live);
        if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[18]^=1;u128 stored;memcpy(&stored,out+1,16);
        if(actual!=(expected^(live^key))||stored!=expected)return mismatch(which,row,"product-live");if(out[17]!=(unsigned)overflow)return mismatch(which,row,"overflow");
        if(out[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=18;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"suffix");
    }else if(which==2){uint8_t context=(uint8_t)row;uint64_t raw=random_word();uint16_t expected=target_bytes(&context,(uint16_t)raw);uint64_t actual=integer_boundaries_target(&context,raw,out+1,live);uint16_t stored;memcpy(&stored,out+1,2);
        if(actual!=((uint64_t)expected^(live^key))||stored!=expected)return mismatch(which,row,"target-abi");if(out[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=3;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"suffix");
    }else{uint64_t rawfill=random_word(),rawlen=random_word(),actual=which==3?integer_boundaries_memset(out+1,rawfill,rawlen,live):integer_boundaries_memset_constant(out+1,rawfill,rawlen,live);unsigned length=which==3?(unsigned)(rawlen&31):32;
        if(actual!=(live^key))return mismatch(which,row,"memory-live");for(unsigned i=0;i<length;++i)if(out[i+1]!=(uint8_t)rawfill)return mismatch(which,row,"memory-bytes");if(out[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=1+length;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"suffix");
    }
    ++observations;return 0;
}
int main(int argc,char **argv){if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;for(unsigned which=0;which<5;++which)for(unsigned row=0;row<8192;++row)if(check(which,row))return 1;if(observations!=40960)return mismatch(0,0,"count");puts("integer-boundaries observations=40960 product=overflow=target=range=live=guards=preserved");return 0;}
