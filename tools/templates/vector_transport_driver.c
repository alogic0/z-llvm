#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static uint64_t random_word(void){static uint64_t state=UINT64_C(0xc123456789abcdef);state^=state<<13;state^=state>>7;state^=state<<17;return state;}
__attribute__((noinline)) uint64_t vector_transport_clobber(uint64_t seed){
    uint64_t result=seed^key;
    __asm__ volatile("xor %%eax,%%eax\n\txor %%ecx,%%ecx\n\txor %%edx,%%edx\n\txor %%edi,%%edi\n\txor %%esi,%%esi\n\txor %%r8d,%%r8d\n\txor %%r9d,%%r9d\n\txor %%r10d,%%r10d\n\txor %%r11d,%%r11d\n\tpxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1\n\tpxor %%xmm2,%%xmm2\n\tpxor %%xmm3,%%xmm3\n\tpxor %%xmm4,%%xmm4\n\tpxor %%xmm5,%%xmm5\n\tpxor %%xmm6,%%xmm6\n\tpxor %%xmm7,%%xmm7\n\tpxor %%xmm8,%%xmm8\n\tpxor %%xmm9,%%xmm9\n\tpxor %%xmm10,%%xmm10\n\tpxor %%xmm11,%%xmm11\n\tpxor %%xmm12,%%xmm12\n\tpxor %%xmm13,%%xmm13\n\tpxor %%xmm14,%%xmm14\n\tpxor %%xmm15,%%xmm15" :::"rax","rcx","rdx","rdi","rsi","r8","r9","r10","r11","xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7","xmm8","xmm9","xmm10","xmm11","xmm12","xmm13","xmm14","xmm15","cc","memory");
    return result;
}
__attribute__((noinline)) __float128 vector_transport_probe(__float128 a,__float128 b){u128 left,right;memcpy(&left,&a,16);memcpy(&right,&b,16);left^=right;memcpy(&a,&left,16);return a;}
static int mismatch(unsigned which,unsigned row,unsigned fault,const char *stage){fprintf(stderr,"vector-transport mismatch case=%u row=%u fault=%u stage=%s\n",which,row,fault,stage);return 1;}
int main(int argc,char **argv){unsigned fault=argc==2?(unsigned)strtoul(argv[1],0,10):0,observations=0;if(argc>2||fault>3)return 2;long page=sysconf(_SC_PAGESIZE);if(page<64)return 2;uint8_t *memory=mmap(0,(size_t)page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(memory==MAP_FAILED||mprotect(memory+page,(size_t)page,PROT_READ|PROT_WRITE))return 2;
    for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which)for(unsigned row=0;row<8192;++row){const struct transport_case *test=&cases[which];u128 raw=row==0?0:row==1?~(u128)0:row==2?(u128)1<<127:((u128)random_word()<<64)|random_word();uint64_t live=random_word();unsigned input_bytes=test->kind==2?16:32,output_bytes=(test->width+7)/8;uint8_t *input=memory+page+((row&1)?page-input_bytes:0);uint8_t original[32],out[24];for(unsigned i=0;i<input_bytes;++i)input[i]=(uint8_t)random_word();memcpy(original,input,input_bytes);memset(out,0xa7,sizeof out);u128 expected;
        if(test->kind==0)expected=raw&(((u128)1<<test->width)-1);
        else if(test->kind==1){uint64_t word;memcpy(&word,original+8*(live&3),8);expected=word;}
        else if(test->kind==2){u128 other;if(test->variant)other=((u128)UINT64_C(0x7fff800000000123)<<64)|UINT64_C(0x0123456789abcdef);else memcpy(&other,original,16);expected=(live&1)?((raw&1)?other:raw):(test->variant?other:raw);}
        else if(test->kind==3)expected=raw^((u128)UINT64_C(0x4000400000000000)<<64);else expected=(uint64_t)raw;
        u128 actual=test->function(raw,input,out+1,live);if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[output_bytes+1]^=1;u128 stored=0;memcpy(&stored,out+1,output_bytes);if(actual!=(expected^(live^key^(test->kind==2?UINT64_C(0xffffffff):0)))||stored!=expected)return mismatch(which,row,fault,"value-live");if(memcmp(input,original,input_bytes))return mismatch(which,row,fault,"input");if(out[0]!=0xa7)return mismatch(which,row,fault,"prefix");for(unsigned i=output_bytes+1;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,fault,"suffix");++observations;
    }
    if(munmap(memory,(size_t)page*3))return 2;puts("vector-transport observations=73728 wide=gep=phi=payloads=staging=guards=live=preserved");return observations==73728?0:2;
}
