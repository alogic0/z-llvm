#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
__attribute__((noinline)) uint64_t half_classification_clobber(uint64_t seed){
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
static unsigned classify(uint16_t raw){unsigned sign=raw>>15,exp=(raw>>10)&31,fraction=raw&1023;if(exp==31)return fraction?(fraction&512?2:1):(sign?4:512);if(!exp)return fraction?(sign?16:128):(sign?32:64);return sign?8:256;}
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"half classification mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
int main(int argc,char **argv){
 if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;long page=sysconf(_SC_PAGESIZE);if(page<4096)return 2;
 uint8_t *mapping=mmap(0,(size_t)page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE))return 2;uint8_t *input=mapping+page-2;
 for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which)for(unsigned row=0;row<65536;++row){uint16_t raw=(uint16_t)row;memcpy(input,&raw,2);unsigned expected=(classify(raw)&cases[which].mask)!=0;uint64_t live=UINT64_C(0x0123456789abcdef)^row;uint8_t out[16];memset(out,0xa7,sizeof out);uint64_t actual=cases[which].function(input,out+1,live);
 if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[2]^=1;
 if(actual!=((uint64_t)expected^(live^key))||out[1]!=expected)return mismatch(which,row,"class-live");if(out[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=2;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"suffix");if(memcmp(input,&raw,2))return mismatch(which,row,"input");++observations;}
 munmap(mapping,(size_t)page*2);puts("half-classification observations=1048576 exhaustive=classes=masks=live=guards=preserved");return observations==1048576?0:2;
}
