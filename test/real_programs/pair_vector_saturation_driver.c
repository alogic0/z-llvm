#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef unsigned __int128 u128;
typedef __int128 i128;
typedef uint64_t (*probe_fn)(void *,const void *,const void *,uint64_t);
struct test_case{unsigned n,op;probe_fn probe;};
static __attribute__((noinline)) u128 model(u128 a,u128 b,unsigned op){
 u128 result,all=~(u128)0,sign=(u128)1<<127;i128 x,y,r;memcpy(&x,&a,16);memcpy(&y,&b,16);
 switch(op){case 0:return __builtin_add_overflow(a,b,&result)?all:result;case 1:return __builtin_sub_overflow(a,b,&result)?0:result;
 case 2:if(__builtin_add_overflow(x,y,&r))return x<0?sign:sign-1;memcpy(&result,&r,16);return result;
 case 3:if(__builtin_sub_overflow(x,y,&r))return x<0?sign:sign-1;memcpy(&result,&r,16);return result;
 case 4:return a<b?a:b;case 5:return a>b?a:b;case 6:return x<y?a:b;case 7:return x>y?a:b;default:abort();}
}
static u128 sample(unsigned seed){u128 sign=(u128)1<<127,all=~(u128)0;u128 values[]={0,1,(u128)UINT64_MAX,(u128)1<<64,sign-1,sign,all-1,all,((u128)UINT64_C(0x123456789abcdef0)<<64)|UINT64_C(0xfedcba9876543210),sign+1};return values[seed%10];}
static size_t observations;
static void check(int pass,unsigned slot,unsigned seed,unsigned fault){observations++;if(!pass){fprintf(stderr,"pair-vector-saturation slot=%u seed=%u observation=%zu fault=%u\n",slot,seed,observations,fault);exit(1);}}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;size_t page=(size_t)sysconf(_SC_PAGESIZE);
 unsigned char *map=mmap(0,page*4,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_NONE)||mprotect(map+3*page,page,PROT_NONE))return 2;
 for(unsigned slot=0;slot<count;slot++)for(unsigned seed=0;seed<128;seed++){
  unsigned n=cases[slot].n,bytes=n*16;unsigned char *ap=map+page-bytes,*bp=map+3*page-bytes;u128 a[32],b[32];
  for(unsigned i=0;i<n;i++){a[i]=sample(seed+i);b[i]=sample(seed*3+i*7);if(seed>=64){a[i]^=((u128)(seed*UINT64_C(0x8123456789abcdef))<<64)|((seed+i)*UINT64_C(0xf06dea67e461de5b));b[i]^=((u128)(seed*UINT64_C(0x361962e2b9c8b6a5))<<64)|~((seed+i)*UINT64_C(0x9e3779b97f4a7c15));}}
  memcpy(ap,a,bytes);memcpy(bp,b,bytes);struct{unsigned char pre[9],data[512],post[9];}out;memset(&out,0xa5,sizeof out);uint64_t salt=(seed+slot*37)*UINT64_C(0xf06dea67e461de5b);
  uint64_t returned=cases[slot].probe(out.data,ap,bp,salt);if(fault==1)returned^=1;if(fault==2)out.data[0]^=1;if(fault==3)out.post[0]^=1;
  check(returned==(salt^90),slot,seed,fault);for(unsigned i=0;i<n;i++){u128 actual;memcpy(&actual,out.data+i*16,16);check(actual==model(a[i],b[i],cases[slot].op),slot,seed,fault);}
  int pre=1,post=1,gap=1;for(unsigned i=0;i<9;i++){pre&=out.pre[i]==0xa5;post&=out.post[i]==0xa5;}for(unsigned i=bytes;i<512;i++)gap&=out.data[i]==0xa5;
  check(pre,slot,seed,fault);check(post,slot,seed,fault);check(gap,slot,seed,fault);check(memcmp(ap,a,bytes)==0,slot,seed,fault);check(memcmp(bp,b,bytes)==0,slot,seed,fault);
 }
 if(munmap(map,page*4)||count!=48||observations!=103424)return 2;printf("pair-vector-saturation observations=%zu signed-unsigned-clamps=extrema=aligned-objects=exact-stores=guard-pages=preserved\n",observations);return 0;
}
extern uint64_t pair_vector_saturation_2_0(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_2_1(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_2_2(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_2_3(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_2_4(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_2_5(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_2_6(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_2_7(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_3_0(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_3_1(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_3_2(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_3_3(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_3_4(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_3_5(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_3_6(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_3_7(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_4_0(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_4_1(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_4_2(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_4_3(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_4_4(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_4_5(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_4_6(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_4_7(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_8_0(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_8_1(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_8_2(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_8_3(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_8_4(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_8_5(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_8_6(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_8_7(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_16_0(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_16_1(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_16_2(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_16_3(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_16_4(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_16_5(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_16_6(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_16_7(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_32_0(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_32_1(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_32_2(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_32_3(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_32_4(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_32_5(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_32_6(void *,const void *,const void *,uint64_t);
extern uint64_t pair_vector_saturation_32_7(void *,const void *,const void *,uint64_t);
static const struct test_case cases[]={
{2,0,pair_vector_saturation_2_0},
{2,1,pair_vector_saturation_2_1},
{2,2,pair_vector_saturation_2_2},
{2,3,pair_vector_saturation_2_3},
{2,4,pair_vector_saturation_2_4},
{2,5,pair_vector_saturation_2_5},
{2,6,pair_vector_saturation_2_6},
{2,7,pair_vector_saturation_2_7},
{3,0,pair_vector_saturation_3_0},
{3,1,pair_vector_saturation_3_1},
{3,2,pair_vector_saturation_3_2},
{3,3,pair_vector_saturation_3_3},
{3,4,pair_vector_saturation_3_4},
{3,5,pair_vector_saturation_3_5},
{3,6,pair_vector_saturation_3_6},
{3,7,pair_vector_saturation_3_7},
{4,0,pair_vector_saturation_4_0},
{4,1,pair_vector_saturation_4_1},
{4,2,pair_vector_saturation_4_2},
{4,3,pair_vector_saturation_4_3},
{4,4,pair_vector_saturation_4_4},
{4,5,pair_vector_saturation_4_5},
{4,6,pair_vector_saturation_4_6},
{4,7,pair_vector_saturation_4_7},
{8,0,pair_vector_saturation_8_0},
{8,1,pair_vector_saturation_8_1},
{8,2,pair_vector_saturation_8_2},
{8,3,pair_vector_saturation_8_3},
{8,4,pair_vector_saturation_8_4},
{8,5,pair_vector_saturation_8_5},
{8,6,pair_vector_saturation_8_6},
{8,7,pair_vector_saturation_8_7},
{16,0,pair_vector_saturation_16_0},
{16,1,pair_vector_saturation_16_1},
{16,2,pair_vector_saturation_16_2},
{16,3,pair_vector_saturation_16_3},
{16,4,pair_vector_saturation_16_4},
{16,5,pair_vector_saturation_16_5},
{16,6,pair_vector_saturation_16_6},
{16,7,pair_vector_saturation_16_7},
{32,0,pair_vector_saturation_32_0},
{32,1,pair_vector_saturation_32_1},
{32,2,pair_vector_saturation_32_2},
{32,3,pair_vector_saturation_32_3},
{32,4,pair_vector_saturation_32_4},
{32,5,pair_vector_saturation_32_5},
{32,6,pair_vector_saturation_32_6},
{32,7,pair_vector_saturation_32_7},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
