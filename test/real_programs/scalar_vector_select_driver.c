#define _GNU_SOURCE
#include <stdint.h>
typedef unsigned __int128 u128;
typedef uint64_t (*choice_fn)(uint64_t,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
struct choice_case {choice_fn function;unsigned size,literal;};
extern uint64_t scalar_vector_select_0(uint64_t,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t scalar_vector_select_1(uint64_t,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t scalar_vector_select_2(uint64_t,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t scalar_vector_select_3(uint64_t,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
static const struct choice_case cases[]={
{scalar_vector_select_0,16,0},
{scalar_vector_select_1,16,1},
{scalar_vector_select_2,8,0},
{scalar_vector_select_3,16,0},
};
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static uint64_t random_word(void){static uint64_t s=UINT64_C(0x6123456789abcdef);s^=s<<13;s^=s>>7;s^=s<<17;return s;}
__attribute__((noinline)) uint64_t scalar_vector_select_clobber(uint64_t seed){
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
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"scalar vector select mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
static int check(uint8_t *left,uint8_t *right,unsigned which,unsigned row){
    const struct choice_case *test=&cases[which];u128 a=((u128)random_word()<<64)|random_word(),b=((u128)random_word()<<64)|random_word();
    if(row<128){a=(u128)1<<row;b=~a;}else if(row<256){b=(u128)1<<(row-128);a=~b;}
    uint64_t choice=random_word(),live=(uint64_t)a^(uint64_t)(b>>64)^row;
    u128 lhs=test->literal?((u128)0x7fff<<112)|1:a,expected=choice&1?lhs:b;
    memcpy(left,&a,test->size);memcpy(right,&b,test->size);uint8_t before_left[16],before_right[16];memcpy(before_left,left,test->size);memcpy(before_right,right,test->size);
    uint8_t out[32];memset(out,0xa7,sizeof out);uint64_t actual=test->function(choice,left,right,out+1,live);
    if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[1+test->size]^=1;
    if(actual!=((live^key)^choice)||memcmp(out+1,&expected,test->size))return mismatch(which,row,"payload-live");
    if(out[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=1+test->size;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"suffix");
    if(memcmp(before_left,left,test->size)||memcmp(before_right,right,test->size))return mismatch(which,row,"inputs-mutated");
    ++observations;return 0;
}
int main(int argc,char **argv){
    if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;long page=sysconf(_SC_PAGESIZE);if(page<4096)return 2;
    uint8_t *mapping=mmap(0,(size_t)page*4,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE)||mprotect(mapping+3*page,(size_t)page,PROT_NONE))return 2;
    for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which)for(unsigned row=0;row<8192;++row)if(check(mapping+page-cases[which].size,mapping+3*page-cases[which].size,which,row))return 1;
    if(observations!=32768)return mismatch(0,0,"count");if(munmap(mapping,(size_t)page*4))return 2;
    puts("scalar-vector-select observations=32768 whole=literal=payloads=live=guards=preserved");return 0;
}
