#include <stdio.h>
#include <stdlib.h>
#include <string.h>
uint32_t storage_table32[16]={0,0x80000000,0x7f800000,0xff800000,0x7f800001,0x7fc12345,1,0x80000001,0x7f7fffff,0xff7fffff,0x00800000,0x80800000,0x3f800000,0xbf800000,0x12345678,0x87654321};
uint64_t storage_table64[16]={0,UINT64_C(0x8000000000000000),UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000),UINT64_C(0x7ff0000000000001),UINT64_C(0x7ff8123456789abc),1,UINT64_C(0x8000000000000001),UINT64_C(0x7fefffffffffffff),(UINT64_MAX ^ UINT64_C(0x0010000000000000)),UINT64_C(0x0010000000000000),UINT64_C(0x8010000000000000),UINT64_C(0x3ff0000000000000),UINT64_C(0xbff0000000000000),UINT64_C(0x123456789abcdef0),UINT64_C(0x87654321fedcba98)};
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static uint64_t random_word(void){static uint64_t s=UINT64_C(0xa123456789abcdef);s^=s<<13;s^=s>>7;s^=s<<17;return s;}
__attribute__((noinline)) uint64_t storage_boundaries_clobber(uint64_t seed){
    uint64_t result=seed^key;
    __asm__ volatile("xor %%eax,%%eax\n\txor %%ecx,%%ecx\n\txor %%edx,%%edx\n\txor %%edi,%%edi\n\txor %%esi,%%esi\n\txor %%r8d,%%r8d\n\txor %%r9d,%%r9d\n\txor %%r10d,%%r10d\n\txor %%r11d,%%r11d\n\tpxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1\n\tpxor %%xmm2,%%xmm2\n\tpxor %%xmm3,%%xmm3\n\tpxor %%xmm4,%%xmm4\n\tpxor %%xmm5,%%xmm5\n\tpxor %%xmm6,%%xmm6\n\tpxor %%xmm7,%%xmm7\n\tpxor %%xmm8,%%xmm8\n\tpxor %%xmm9,%%xmm9\n\tpxor %%xmm10,%%xmm10\n\tpxor %%xmm11,%%xmm11\n\tpxor %%xmm12,%%xmm12\n\tpxor %%xmm13,%%xmm13\n\tpxor %%xmm14,%%xmm14\n\tpxor %%xmm15,%%xmm15" :::"rax","rcx","rdx","rdi","rsi","r8","r9","r10","r11","xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7","xmm8","xmm9","xmm10","xmm11","xmm12","xmm13","xmm14","xmm15","cc","memory");
    return result;
}
int main(int argc,char **argv){unsigned fault=argc==2?(unsigned)strtoul(argv[1],0,10):0,observations=0;if(argc>2||fault>3)return 2;
    for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which)for(unsigned row=0;row<8192;++row){const struct storage_case *test=&cases[which];uint64_t raw=random_word(),live=random_word(),initial=random_word(),expected;unsigned bytes=test->bits/8;uint64_t mask=bytes==4?UINT64_C(0xffffffff):UINT64_MAX;uint8_t input[24],out[24];memset(input,0x5a,sizeof input);memset(out,0xa7,sizeof out);memcpy(input+1,&initial,bytes);
        if(test->bytes){expected=raw^((raw&255)|((live&255)<<8)|(((raw^live)&255)<<16));}
        else{expected=(test->merged&&!(live&1)?initial:(bytes==4?storage_table32[raw&15]:storage_table64[raw&15]))&mask;}
        uint64_t actual=test->function(raw,input+1,out+1,live);if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[bytes+1]^=1;uint64_t stored=0,after=0;memcpy(&stored,out+1,bytes);memcpy(&after,input+1,bytes);
        if(actual!=(expected^(live^key))||stored!=expected||after!=((test->bytes?initial:raw)&mask)){fprintf(stderr,"storage mismatch case=%u row=%u fault=%u expected=%llx actual=%llx stored=%llx after=%llx\n",which,row,fault,(unsigned long long)expected,(unsigned long long)actual,(unsigned long long)stored,(unsigned long long)after);return 1;}
        if(input[0]!=0x5a||out[0]!=0xa7){fprintf(stderr,"storage prefix mismatch case=%u row=%u fault=%u\n",which,row,fault);return 1;}for(unsigned i=bytes+1;i<sizeof out;++i)if(input[i]!=0x5a||out[i]!=0xa7){fprintf(stderr,"storage suffix mismatch case=%u row=%u fault=%u offset=%u\n",which,row,fault,i);return 1;}++observations;
    }
    puts("storage-boundaries observations=57344 tables=merged=payloads=objects=pages=guards=live=preserved");return observations==57344?0:2;
}
