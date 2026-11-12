#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef unsigned __int128 u128;
typedef __int128 i128;
typedef u128 (*body_fn)(u128,u128);
typedef uint64_t (*probe_fn)(void *,const void *,const void *,uint64_t);
struct test_case{unsigned op;body_fn body;probe_fn probe;};
static __attribute__((noinline)) u128 model(u128 a,u128 b,unsigned op){
 u128 result,all=~(u128)0,sign=(u128)1<<127;if(op>=8){if(op<10)a=all-1;else b=all-1;op=4+(op&1);}i128 x,y,r;memcpy(&x,&a,16);memcpy(&y,&b,16);
 switch(op){case 0:return __builtin_add_overflow(a,b,&result)?all:result;case 1:return __builtin_sub_overflow(a,b,&result)?0:result;
 case 2:if(__builtin_add_overflow(x,y,&r))return x<0?sign:sign-1;memcpy(&result,&r,16);return result;
 case 3:if(__builtin_sub_overflow(x,y,&r))return x<0?sign:sign-1;memcpy(&result,&r,16);return result;
 case 4:return a<b?a:b;case 5:return a>b?a:b;case 6:return x<y?a:b;case 7:return x>y?a:b;default:abort();}
}
static u128 sample(unsigned seed){u128 sign=(u128)1<<127,all=~(u128)0;u128 values[]={0,1,(u128)UINT64_MAX,(u128)1<<64,sign-1,sign,all-1,all,((u128)UINT64_C(0x123456789abcdef0)<<64)|UINT64_C(0xfedcba9876543210),sign+1};return values[seed%10];}
static size_t observations;
static void check(int pass,unsigned slot,unsigned seed,unsigned fault){observations++;if(!pass){fprintf(stderr,"pair-saturation slot=%u seed=%u observation=%zu fault=%u\n",slot,seed,observations,fault);exit(1);}}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;size_t page=(size_t)sysconf(_SC_PAGESIZE);
 unsigned char *map=mmap(0,page*4,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_NONE)||mprotect(map+3*page,page,PROT_NONE))return 2;
 unsigned char *ap=map+page-16,*bp=map+3*page-16;
 for(unsigned slot=0;slot<count;slot++)for(unsigned seed=0;seed<256;seed++){
  u128 a=sample(seed/10),b=sample(seed%10);if(seed>=100){a^=((u128)(seed*UINT64_C(0x8123456789abcdef))<<64)|(seed*UINT64_C(0xf06dea67e461de5b));b^=((u128)(seed*UINT64_C(0x361962e2b9c8b6a5))<<64)|~(seed*UINT64_C(0x9e3779b97f4a7c15));}
  memcpy(ap,&a,16);memcpy(bp,&b,16);u128 expected=model(a,b,cases[slot].op);check(cases[slot].body(a,b)==expected,slot,seed,fault);
  struct{unsigned char pre[9],data[32],post[9];}out;memset(&out,0xa5,sizeof out);uint64_t salt=(seed+slot*37)*UINT64_C(0xf06dea67e461de5b);
  uint64_t returned=cases[slot].probe(out.data,ap,bp,salt);if(fault==1)returned^=1;if(fault==2)out.data[0]^=1;if(fault==3)out.post[0]^=1;
  check(returned==(salt^90),slot,seed,fault);check(memcmp(out.data,&expected,16)==0,slot,seed,fault);check(memcmp(out.data+16,&expected,16)==0,slot,seed,fault);
  int pre=1,post=1;for(unsigned i=0;i<9;i++){pre&=out.pre[i]==0xa5;post&=out.post[i]==0xa5;}check(pre,slot,seed,fault);check(post,slot,seed,fault);check(memcmp(ap,&a,16)==0,slot,seed,fault);check(memcmp(bp,&b,16)==0,slot,seed,fault);
 }
 if(munmap(map,page*4)||count!=4||observations!=8192)return 2;printf("pair-literal-extrema observations=%zu unsigned-minmax=left-right-full-width-literals=llvm-c-local-interop=guards=preserved\n",observations);return 0;
}
extern u128 pair_literal_extrema_body_8(u128,u128);
extern uint64_t pair_literal_extrema_probe_8(void *,const void *,const void *,uint64_t);
u128 pair_literal_extrema_provider_8(u128 a,u128 b){return model(a,b,8);}
extern u128 pair_literal_extrema_body_9(u128,u128);
extern uint64_t pair_literal_extrema_probe_9(void *,const void *,const void *,uint64_t);
u128 pair_literal_extrema_provider_9(u128 a,u128 b){return model(a,b,9);}
extern u128 pair_literal_extrema_body_10(u128,u128);
extern uint64_t pair_literal_extrema_probe_10(void *,const void *,const void *,uint64_t);
u128 pair_literal_extrema_provider_10(u128 a,u128 b){return model(a,b,10);}
extern u128 pair_literal_extrema_body_11(u128,u128);
extern uint64_t pair_literal_extrema_probe_11(void *,const void *,const void *,uint64_t);
u128 pair_literal_extrema_provider_11(u128 a,u128 b){return model(a,b,11);}
static const struct test_case cases[]={
{8,pair_literal_extrema_body_8,pair_literal_extrema_probe_8},
{9,pair_literal_extrema_body_9,pair_literal_extrema_probe_9},
{10,pair_literal_extrema_body_10,pair_literal_extrema_probe_10},
{11,pair_literal_extrema_body_11,pair_literal_extrema_probe_11},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
