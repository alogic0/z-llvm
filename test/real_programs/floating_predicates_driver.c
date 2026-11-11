#define _GNU_SOURCE
#include <stdint.h>
typedef unsigned __int128 u128;
typedef uint64_t (*predicate_fn)(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
struct predicate_case {predicate_fn function;unsigned format,predicate,rows;};
extern uint64_t floating_predicate_half_false(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_oeq(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_ogt(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_oge(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_olt(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_ole(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_one(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_ord(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_ueq(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_ugt(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_uge(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_ult(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_ule(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_une(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_uno(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_true(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_half_mask(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_false(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_oeq(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_ogt(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_oge(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_olt(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_ole(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_one(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_ord(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_ueq(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_ugt(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_uge(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_ult(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_ule(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_une(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_uno(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_true(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
extern uint64_t floating_predicate_extended_mask(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);
static const struct predicate_case cases[]={
{floating_predicate_half_false,0,0,65792},
{floating_predicate_half_oeq,0,1,65792},
{floating_predicate_half_ogt,0,2,65792},
{floating_predicate_half_oge,0,3,65792},
{floating_predicate_half_olt,0,4,65792},
{floating_predicate_half_ole,0,5,65792},
{floating_predicate_half_one,0,6,65792},
{floating_predicate_half_ord,0,7,65792},
{floating_predicate_half_ueq,0,8,65792},
{floating_predicate_half_ugt,0,9,65792},
{floating_predicate_half_uge,0,10,65792},
{floating_predicate_half_ult,0,11,65792},
{floating_predicate_half_ule,0,12,65792},
{floating_predicate_half_une,0,13,65792},
{floating_predicate_half_uno,0,14,65792},
{floating_predicate_half_true,0,15,65792},
{floating_predicate_half_mask,0,16,65792},
{floating_predicate_extended_false,1,0,8192},
{floating_predicate_extended_oeq,1,1,8192},
{floating_predicate_extended_ogt,1,2,8192},
{floating_predicate_extended_oge,1,3,8192},
{floating_predicate_extended_olt,1,4,8192},
{floating_predicate_extended_ole,1,5,8192},
{floating_predicate_extended_one,1,6,8192},
{floating_predicate_extended_ord,1,7,8192},
{floating_predicate_extended_ueq,1,8,8192},
{floating_predicate_extended_ugt,1,9,8192},
{floating_predicate_extended_uge,1,10,8192},
{floating_predicate_extended_ult,1,11,8192},
{floating_predicate_extended_ule,1,12,8192},
{floating_predicate_extended_une,1,13,8192},
{floating_predicate_extended_uno,1,14,8192},
{floating_predicate_extended_true,1,15,8192},
{floating_predicate_extended_mask,1,16,8192},
};
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <float.h>
_Static_assert(sizeof(long double)==16&&LDBL_MANT_DIG==64&&LDBL_MAX_EXP==16384,"requires extended80 ABI");
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static uint64_t random_word(void){static uint64_t s=UINT64_C(0x3123456789abcdef);s^=s<<13;s^=s>>7;s^=s<<17;return s;}
static u128 mask80(void){return((u128)1<<80)-1;}
static void write_bits(uint8_t *p,u128 v,unsigned n){for(unsigned i=0;i<n;++i)p[i]=(uint8_t)(v>>(8*i));}
__attribute__((noinline)) uint64_t floating_predicate_clobber(uint64_t seed){
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
static int truth(unsigned predicate,int unordered,int less,int equal,int greater){
    switch(predicate){case 0:return 0;case 1:return!unordered&&equal;case 2:return!unordered&&greater;
    case 3:return!unordered&&(greater||equal);case 4:return!unordered&&less;case 5:return!unordered&&(less||equal);
    case 6:return!unordered&&!equal;case 7:return!unordered;case 8:return unordered||equal;case 9:return unordered||greater;
    case 10:return unordered||greater||equal;case 11:return unordered||less;case 12:return unordered||less||equal;
    case 13:return unordered||!equal;case 14:return unordered;case 15:return 1;default:abort();}
}
/* The oracle deliberately executes hardware FP comparisons, independently of
   the selector's integer representation algorithm. */
__attribute__((noinline)) static uint64_t native_truth(unsigned format,unsigned predicate,const uint8_t *a,const uint8_t *b){
    int unordered,less,equal,greater;
    if(format==0){_Float16 ah,bh;memcpy(&ah,a,2);memcpy(&bh,b,2);float x=ah,y=bh;unordered=x!=x||y!=y;less=x<y;equal=x==y;greater=x>y;}
    else{uint8_t ab[16]={0},bb[16]={0};memcpy(ab,a,10);memcpy(bb,b,10);long double x,y;memcpy(&x,ab,16);memcpy(&y,bb,16);unordered=x!=x||y!=y;less=x<y;equal=x==y;greater=x>y;}
    if(predicate<16)return truth(predicate,unordered,less,equal,greater);
    uint64_t result=0;for(unsigned i=0;i<16;++i)result|=(uint64_t)truth(i,unordered,less,equal,greater)<<i;return result;
}
static const uint16_t half_edges[]={0,0x8000,1,0x8001,0x3ff,0x400,0x3c00,0xbc00,0x7bff,0xfbff,0x7c00,0xfc00,0x7e01,0x7c01,0xfe01,0xfc01};
static const u128 extended_edges[]={0,(u128)0x8000<<64,1,((u128)0x8000<<64)|1,
    (u128)UINT64_C(0x8000000000000000),((u128)1<<64)|UINT64_C(0x8000000000000000),
    ((u128)0x3fff<<64)|UINT64_C(0x8000000000000000),((u128)0xbfff<<64)|UINT64_C(0x8000000000000000),
    ((u128)0x7fff<<64)|UINT64_C(0x8000000000000000),((u128)0xffff<<64)|UINT64_C(0x8000000000000000),
    ((u128)0x7fff<<64)|UINT64_C(0xc000000000000123),((u128)0x7fff<<64)|UINT64_C(0x8000000000000001),
    ((u128)0xffff<<64)|UINT64_C(0xc000000000000123),(u128)0x3fff<<64,(u128)0x7fff<<64,
    ((u128)0x7ffe<<64)|UINT64_MAX};
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"floating predicate mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
static int check(uint8_t *left,uint8_t *right,unsigned which,unsigned row){
    const struct predicate_case *test=&cases[which];unsigned size=test->format?10:2;u128 a,b;
    if(test->format==0){if(row<256){a=half_edges[row/16];b=half_edges[row%16];}else{a=row-256;b=half_edges[(row-256)%16];}}
    else if(row<256){a=extended_edges[row/16];b=extended_edges[row%16];}
    else{a=(((u128)random_word()<<64)|random_word())&mask80();b=(((u128)random_word()<<64)|random_word())&mask80();
        if(row&1){if(((a>>64)&0x7fff)!=0)a|=(u128)1<<63;else a&=~((u128)1<<63);if(((b>>64)&0x7fff)!=0)b|=(u128)1<<63;else b&=~((u128)1<<63);}}
    write_bits(left,a,size);write_bits(right,b,size);uint8_t before_left[10],before_right[10];memcpy(before_left,left,size);memcpy(before_right,right,size);
    uint64_t expected=native_truth(test->format,test->predicate,left,right),live=(uint64_t)a^(uint64_t)(b>>64)^row;
    uint8_t out[24];memset(out,0xa7,sizeof out);uint64_t actual=test->function(left,right,out+1,live);
    if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[9]^=1;uint64_t stored;memcpy(&stored,out+1,8);
    if(actual!=(expected^(live^key))||stored!=expected)return mismatch(which,row,"predicate-live");
    if(out[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=9;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"suffix");
    if(memcmp(before_left,left,size)||memcmp(before_right,right,size))return mismatch(which,row,"inputs-mutated");
    ++observations;return 0;
}
int main(int argc,char **argv){
    if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;long page=sysconf(_SC_PAGESIZE);if(page<4096)return 2;
    uint8_t *mapping=mmap(0,(size_t)page*4,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE)||mprotect(mapping+3*page,(size_t)page,PROT_NONE))return 2;
    for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which){unsigned size=cases[which].format?10:2;
        for(unsigned row=0;row<cases[which].rows;++row)if(check(mapping+page-size,mapping+3*page-size,which,row))return 1;}
    if(observations!=1257728)return mismatch(0,0,"count");if(munmap(mapping,(size_t)page*4))return 2;
    puts("floating-predicates observations=1257728 ordered=unordered=half=extended=live=guards=preserved");return 0;
}
