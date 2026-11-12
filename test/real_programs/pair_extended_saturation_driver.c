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
 u128 all=~(u128)0,sign=(u128)1<<127,result;unsigned n=(unsigned)(b&127);op&=3;
 if(op==0)result=a>(all>>n)?all:a<<n;
 else if(op==1){int negative=(a&sign)!=0;u128 magnitude=negative?(u128)0-a:a,limit=negative?sign:sign-1;if(magnitude>(limit>>n))result=negative?sign:sign-1;else{result=magnitude<<n;if(negative)result=(u128)0-result;}}
 else if(op==2){if(__builtin_mul_overflow(a,b,&result))result=all;}
 else{i128 x,y,r;memcpy(&x,&a,16);memcpy(&y,&b,16);if(__builtin_mul_overflow(x,y,&r))result=((x<0)^(y<0))?sign:sign-1;else memcpy(&result,&r,16);}
 return result^b;
}

static u128 sample(unsigned seed){u128 sign=(u128)1<<127,all=~(u128)0;u128 values[]={0,1,(u128)UINT64_MAX,(u128)1<<64,sign-1,sign,all-1,all,((u128)UINT64_C(0x123456789abcdef0)<<64)|UINT64_C(0xfedcba9876543210),sign+1};return values[seed%10];}
static size_t observations;
static void check(int pass,unsigned slot,unsigned seed,unsigned fault){observations++;if(!pass){fprintf(stderr,"pair-extended slot=%u seed=%u observation=%zu fault=%u\n",slot,seed,observations,fault);exit(1);}}
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
 if(munmap(map,page*4)||count!=8||observations!=16384)return 2;printf("pair-extended observations=%zu signed-unsigned-shifts=full-products=scale-zero=live-words=llvm-c-local-interop=guards=preserved\n",observations);return 0;
}
extern u128 pair_extended_body_0(u128,u128);
extern uint64_t pair_extended_probe_0(void *,const void *,const void *,uint64_t);
u128 pair_extended_provider_0(u128 a,u128 b){return model(a,b,0);}
extern u128 pair_extended_body_1(u128,u128);
extern uint64_t pair_extended_probe_1(void *,const void *,const void *,uint64_t);
u128 pair_extended_provider_1(u128 a,u128 b){return model(a,b,1);}
extern u128 pair_extended_body_2(u128,u128);
extern uint64_t pair_extended_probe_2(void *,const void *,const void *,uint64_t);
u128 pair_extended_provider_2(u128 a,u128 b){return model(a,b,2);}
extern u128 pair_extended_body_3(u128,u128);
extern uint64_t pair_extended_probe_3(void *,const void *,const void *,uint64_t);
u128 pair_extended_provider_3(u128 a,u128 b){return model(a,b,3);}
extern u128 pair_extended_body_4(u128,u128);
extern uint64_t pair_extended_probe_4(void *,const void *,const void *,uint64_t);
u128 pair_extended_provider_4(u128 a,u128 b){return model(a,b,4);}
extern u128 pair_extended_body_5(u128,u128);
extern uint64_t pair_extended_probe_5(void *,const void *,const void *,uint64_t);
u128 pair_extended_provider_5(u128 a,u128 b){return model(a,b,5);}
extern u128 pair_extended_body_6(u128,u128);
extern uint64_t pair_extended_probe_6(void *,const void *,const void *,uint64_t);
u128 pair_extended_provider_6(u128 a,u128 b){return model(a,b,6);}
extern u128 pair_extended_body_7(u128,u128);
extern uint64_t pair_extended_probe_7(void *,const void *,const void *,uint64_t);
u128 pair_extended_provider_7(u128 a,u128 b){return model(a,b,7);}
static const struct test_case cases[]={
{0,pair_extended_body_0,pair_extended_probe_0},
{1,pair_extended_body_1,pair_extended_probe_1},
{2,pair_extended_body_2,pair_extended_probe_2},
{3,pair_extended_body_3,pair_extended_probe_3},
{4,pair_extended_body_4,pair_extended_probe_4},
{5,pair_extended_body_5,pair_extended_probe_5},
{6,pair_extended_body_6,pair_extended_probe_6},
{7,pair_extended_body_7,pair_extended_probe_7},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
