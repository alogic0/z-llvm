#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
extern uint64_t vector_counts_range(const uint8_t*,uint8_t*,uint64_t);
extern uint64_t vector_counts_mask(const uint8_t*,uint8_t*,uint64_t);
extern uint64_t vector_counts_min(const uint8_t*,uint8_t*,uint64_t);
extern uint64_t vector_counts_shuffle(const uint8_t*,uint8_t*,uint64_t);
typedef uint64_t (*vector_fn)(const uint8_t*,uint8_t*,uint64_t);
static const vector_fn cases[]={vector_counts_range,vector_counts_mask,vector_counts_min,vector_counts_shuffle};
static const unsigned inputs[]={48,16,8,16},outputs[]={48,2,1,16};
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static uint64_t random_word(void){static uint64_t s=UINT64_C(0xa123456789abcdef);s^=s<<13;s^=s>>7;s^=s<<17;return s;}
__attribute__((noinline)) uint64_t vector_counts_clobber(uint64_t seed){
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
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"vector counts mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
int main(int argc,char **argv){if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;long page=sysconf(_SC_PAGESIZE);if(page<4096)return 2;uint8_t *mapping=mmap(0,(size_t)page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE))return 2;
 for(unsigned which=0;which<4;++which)for(unsigned row=0;row<8192;++row){uint8_t *input=mapping+page-inputs[which],before[48],expected[48]={0},out[64];for(unsigned i=0;i<inputs[which];++i)input[i]=row==0?0:row==1?255:(uint8_t)random_word();memcpy(before,input,inputs[which]);uint64_t value=0,live=random_word();memset(out,0xa7,sizeof out);
 if(which==0){for(unsigned lane=0;lane<6;++lane){uint64_t raw,count=0;memcpy(&raw,input+lane*8,8);while(raw){raw&=raw-1;++count;}memcpy(expected+lane*8,&count,8);value+=count;}}
 else if(which==1){uint16_t mask=0;for(unsigned lane=0;lane<16;++lane)if(!input[lane])mask|=(uint16_t)(1u<<lane);memcpy(expected,&mask,2);value=mask;}
 else if(which==2){uint64_t raw;memcpy(&raw,input,8);value=15;for(unsigned lane=0;lane<16;++lane){unsigned nibble=(unsigned)(raw>>(4*lane))&15;if(nibble<value)value=nibble;}expected[0]=(uint8_t)value;}
 else{uint64_t left,right;memcpy(&left,input,8);memcpy(&right,input+8,8);memcpy(expected,&right,8);memcpy(expected+8,&left,8);value=left^right;}
 uint64_t actual=cases[which](input,out+1,live);if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[1+outputs[which]]^=1;if(actual!=(value^(live^key))||memcmp(expected,out+1,outputs[which]))return mismatch(which,row,"lanes-live");if(out[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=1+outputs[which];i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"suffix");if(memcmp(before,input,inputs[which]))return mismatch(which,row,"input");++observations;}
 munmap(mapping,(size_t)page*2);puts("vector-counts observations=32768 range=popcount=masks=reduction=shuffle=live=guards=preserved");return observations==32768?0:2;
}
