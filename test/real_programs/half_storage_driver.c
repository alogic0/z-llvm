#define _GNU_SOURCE
#include <stdint.h>
typedef uint64_t (*storage_fn)(uint16_t,const uint8_t*,uint8_t*,uint64_t);
struct storage_case {storage_fn function;unsigned kind;};
extern uint64_t half_storage_argument(uint16_t,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_storage_input(uint16_t,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_storage_signaling_nan(uint16_t,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t half_storage_negative_zero(uint16_t,const uint8_t*,uint8_t*,uint64_t);
static const struct storage_case cases[]={
{half_storage_argument,0},
{half_storage_input,1},
{half_storage_signaling_nan,2},
{half_storage_negative_zero,3},
};
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
__attribute__((noinline)) uint64_t half_storage_clobber(uint64_t seed){
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
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"half storage mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
static int check(uint8_t *input,unsigned which,unsigned row){
    const struct storage_case *test=&cases[which];uint16_t source=(uint16_t)(row^0xa55a);memcpy(input,&source,2);
    uint16_t first=test->kind==0?(uint16_t)row:test->kind==1?source:test->kind==2?0x7d01:0x8000;
    uint64_t live=UINT64_C(0xface123456789abc)^row;unsigned offset=live&1?3:14;
    uint8_t expected[16];memset(expected,0xa7,sizeof expected);expected[offset]=1;expected[offset+1]=0x3c;
    uint8_t out[24];memset(out,0xa7,sizeof out);uint64_t actual=test->function((uint16_t)row,input,out+1,live);
    if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[17]^=1;
    if(actual!=((uint64_t)first^(live^key)))return mismatch(which,row,"captured-live");
    if(memcmp(out+1,expected,16))return mismatch(which,row,"owned-object");
    if(out[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=17;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"suffix");
    uint16_t unchanged;memcpy(&unchanged,input,2);if(unchanged!=source)return mismatch(which,row,"input-mutated");
    ++observations;return 0;
}
int main(int argc,char **argv){
    if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;long page=sysconf(_SC_PAGESIZE);if(page<4096)return 2;
    uint8_t *mapping=mmap(0,(size_t)page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE))return 2;
    for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which)for(unsigned row=0;row<65536;++row)if(check(mapping+page-2,which,row))return 1;
    if(observations!=262144)return mismatch(0,0,"count");if(munmap(mapping,(size_t)page*2))return 2;
    puts("half-storage observations=262144 store-only=phi=capture=payloads=live=guards=preserved");return 0;
}
