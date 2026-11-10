#include <stdint.h>
#include <stdbool.h>
extern uint64_t stack_copy_i8(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);
extern uint64_t stack_copy_i16(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);
extern uint64_t stack_copy_i32(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);
extern uint64_t stack_copy_i64(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);
extern uint64_t stack_copy_f32(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);
extern uint64_t stack_copy_f64(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);
extern uint64_t stack_copy_i128(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);
extern uint64_t stack_copy_array3(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);
extern uint64_t stack_copy_array16(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);
typedef uint64_t (*copy_fn)(unsigned char*,const unsigned char*,const unsigned char*,unsigned char*,uint64_t,uint64_t);
static const struct { copy_fn run; unsigned bytes; } copies[]={
 {stack_copy_i8,1},
 {stack_copy_i16,2},
 {stack_copy_i32,4},
 {stack_copy_i64,8},
 {stack_copy_f32,4},
 {stack_copy_f64,8},
 {stack_copy_i128,16},
 {stack_copy_array3,12},
 {stack_copy_array16,64},
};
extern uint64_t stack_phi_i64(const uint64_t*,uint64_t,bool,uint64_t);
extern uint64_t stack_phi_i128(const uint64_t*,uint64_t,bool,uint64_t);
extern uint64_t stack_phi_array3(const uint64_t*,uint64_t,bool,uint64_t);
extern uint64_t stack_phi_array16(const uint64_t*,uint64_t,bool,uint64_t);
static uint64_t (*const choices[])(const uint64_t*,uint64_t,bool,uint64_t)={stack_phi_i64,stack_phi_i128,stack_phi_array3,stack_phi_array16};
extern uint64_t stack_phi_swap_2(uint64_t,uint64_t,uint32_t,uint64_t);
extern uint64_t stack_phi_swap_16(uint64_t,uint64_t,uint32_t,uint64_t);
static uint64_t (*const swaps[])(uint64_t,uint64_t,uint32_t,uint64_t)={stack_phi_swap_2,stack_phi_swap_16};
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
extern uint64_t stack_window(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t stack_move(unsigned char*,const unsigned char*,uint64_t,uint64_t,uint64_t);
extern uint64_t stack_call_array(const unsigned char*,unsigned char*,uint64_t);
extern uint64_t stack_call_bool(const unsigned char*,unsigned char*,uint64_t);
static unsigned observations,fault;
static int mismatch(const char *kind) {
 fprintf(stderr,"stack object mismatch kind=%s fault=%u observation=%u\n",kind,fault,observations); return 1;
}
static void clobber(void) {
 __asm__ volatile("movabs $0x1122334455667788,%%rax\n\t"
 "movabs $0x8877665544332211,%%rcx\n\t"
 "movabs $0x9988776655443322,%%rdx\n\t"
 "movabs $0xaabbccddeeff0011,%%rdi\n\t"
 "movabs $0xbbaa998877665544,%%rsi\n\t"
 "movabs $0xccddeeff00112233,%%r8\n\t"
 "movabs $0xddccbbaa99887766,%%r9\n\t"
 "movabs $0xeeff001122334455,%%r10\n\t"
 "movabs $0xffeeddccbbaa9988,%%r11\n\t"
 "pxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1"
 :::"rax","rcx","rdx","rdi","rsi","r8","r9","r10","r11","xmm0","xmm1","cc","memory");
}
__attribute__((noinline)) uint64_t stack_object_touch(unsigned char *p,uint64_t seed) {
 uint64_t a,b; memcpy(&a,p,8); memcpy(&b,p+56,8);
 p[0]^=0x5a; p[63]^=0xa5; clobber(); return (a+b)^(seed+UINT64_C(0x9e3779b97f4a7c15));
}
__attribute__((noinline)) bool stack_object_predicate(unsigned char *p,uint64_t seed) {
 bool result=((p[0]+p[63]+seed)&1)!=0; clobber(); return result;
}
static int copy_check(unsigned c,const unsigned char *input,unsigned length,uint64_t seed) {
 unsigned size=copies[c].bytes;
 unsigned char alternate[64],before[64],out[96],source[96],expected[96],source_expected[96];
 memcpy(before,input,size); for(unsigned j=0;j<size;j++)alternate[j]=input[j]^0xa7;
 memset(out,0x93,sizeof(out)); memset(source,0xc6,sizeof(source));
 memcpy(expected,out,sizeof(out)); memcpy(source_expected,source,sizeof(source));
 memcpy(expected+5,alternate,size); memcpy(expected+5,input,length); memcpy(source_expected+7,input,size);
 uint64_t result=copies[c].run(out+5,input,alternate,source+7,length,seed);
 if(fault==1)result^=1; if(fault==2)out[5]^=1; if(fault==3)source[7]^=1;
 if(fault==4)out[4]^=1; if(fault==5)out[5+size]^=1; if(fault==6)source[6]^=1;
 if(result!=(seed^size)||memcmp(out,expected,sizeof(out))||memcmp(source,source_expected,sizeof(source))||memcmp(input,before,size))return mismatch("copy");
 observations++; return 0;
}
int main(int argc,char **argv) {
 if(argc==2)fault=(unsigned)strtoul(argv[1],0,10); if(argc>2||fault>10)return 2;
 const uint64_t values[]={0,UINT64_C(0x0123456789abcdef),UINT64_C(0xfedcba9876543210),UINT64_MAX};
 const uint64_t seeds[]={0,1,UINT64_MAX};
 for(unsigned p=0;p<4;p++) {
  unsigned char input[64],before[64]; for(unsigned j=0;j<64;j++)input[j]=(unsigned char)(((p+1)*37+j*29)^(j>>(p%3)));
  memcpy(before,input,64);
  for(unsigned s=0;s<3;s++) {
   uint64_t seed=seeds[s];
   for(unsigned c=0;c<9;c++)for(unsigned n=0;n<=copies[c].bytes;n++)if(copy_check(c,input,n,seed))return 1;
   for(unsigned c=0;c<4;c++)for(unsigned local=0;local<2;local++) {
    uint64_t external=values[p]^UINT64_C(0x8000000000000001);
    uint64_t actual=choices[c](&external,values[p],local!=0,seed);
    if(fault==8)actual^=1;
    if(actual!=((local?values[p]:external)^seed)||external!=(values[p]^UINT64_C(0x8000000000000001)))return mismatch("phi-branch");
    observations++;
   }
   for(unsigned c=0;c<2;c++)for(unsigned b=0;b<3;b++)for(unsigned n=0;n<19;n++) {
    uint64_t actual=swaps[c](values[p],values[b+1],n,seed);
    uint64_t difference=n&1?values[b+1]-values[p]:values[p]-values[b+1];
    if(actual!=(difference^seed))return mismatch("phi-loop"); observations++;
   }
   for(unsigned offset=0;offset<=8;offset++)for(unsigned n=0;n<=8-offset;n++) {
    unsigned char out[24],expected[24]; memset(out,0x93,24); memcpy(expected,out,24);
    memcpy(expected+5,(const unsigned char*)&values[p]+offset,n);
    uint64_t actual=stack_window(out+5,values[p],offset,n,seed); if(fault==7)actual^=1;
    if(actual!=(values[p]^seed)||memcmp(out,expected,24))return mismatch("window"); observations++;
   }
   for(unsigned offset=0;offset<8;offset++)for(unsigned n=0;n<=64-offset;n++) {
    unsigned char out[80],expected[80]; memset(out,0x93,80); memcpy(expected,out,80); memcpy(expected+5,input,64);
    if(seed&1)memmove(expected+5+offset,expected+5,n); else memmove(expected+5,expected+5+offset,n);
    uint64_t actual=stack_move(out+5,input,offset,n,seed); if(fault==10)actual^=1;
    if(actual!=(seed^n)||memcmp(out,expected,80)||memcmp(input,before,64))return mismatch("move"); observations++;
   }
   for(unsigned boolean=0;boolean<2;boolean++) {
    unsigned char out[80],expected[80]; memset(out,0x93,80); memcpy(expected,out,80); memcpy(expected+5,input,64);
    uint64_t a,b; memcpy(&a,input,8); memcpy(&b,input+56,8);
    uint64_t result=boolean?((input[0]+input[63]+seed)&1):((a+b)^(seed+UINT64_C(0x9e3779b97f4a7c15)));
    if(!boolean){expected[5]^=0x5a;expected[68]^=0xa5;}
    uint64_t actual=boolean?stack_call_bool(input,out+5,seed):stack_call_array(input,out+5,seed); if(fault==9)actual^=1;
    if(actual!=(result^seed)||memcmp(out,expected,80)||memcmp(input,before,64))return mismatch("call"); observations++;
   }
  }
 }
 long page=sysconf(_SC_PAGESIZE); if(page<64)return 2;
 unsigned char *mapping=mmap(0,(size_t)page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE))return 2;
 for(unsigned j=0;j<64;j++)mapping[page-64+j]=(unsigned char)(j*37+19);
 for(unsigned c=0;c<9;c++)if(copy_check(c,mapping+page-copies[c].bytes,copies[c].bytes,UINT64_MAX))return 1;
 for(unsigned n=0;n<3;n++) {
  unsigned length=n==2?8:n; uint64_t value=values[1];
  if(stack_window(mapping+page-length,value,8-length,length,1)!=(value^1)||memcmp(mapping+page-length,(unsigned char*)&value+8-length,length))return mismatch("page-edge"); observations++;
 }
 if(munmap(mapping,(size_t)page*2))return 2;
 if(observations!=9480)return mismatch("count");
 puts("stack-object-addresses observations=9480 copies=offsets=phis=loops=overlap=calls=guards=preserved"); return 0;
}
