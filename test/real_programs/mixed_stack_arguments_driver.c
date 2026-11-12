#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef unsigned __int128 u128;
typedef uint64_t Carrier __attribute__((vector_size(16)));
typedef uint64_t (*probe_fn)(const void *,uint64_t,uint64_t);
struct test_case{unsigned kind;probe_fn run;};
static const uint64_t prefix[]={UINT64_C(0x123456789abcdef0),UINT64_C(0xfedcba9876543210),UINT64_C(0x1122334455667788),UINT64_C(0xabcd0123456789ef),UINT64_C(0x87654321fedcba98),UINT64_C(0x1020304050607080),UINT64_C(0xf1379bdf2468ace0)};
static volatile unsigned calls;
static uint64_t model(const uint64_t *pre,u128 pair,uint64_t fp0,uint64_t fp1,uint64_t salt){for(unsigned i=0;i<7;i++)salt=salt*UINT64_C(1099511628211)^pre[i];salt=salt*UINT64_C(1099511628211)^(uint64_t)pair;salt=salt*UINT64_C(1099511628211)^(uint64_t)(pair>>64);salt=salt*UINT64_C(1099511628211)^fp0;return salt*UINT64_C(1099511628211)^fp1;}
static size_t observations;
static void check(int pass,unsigned slot,unsigned seed,unsigned fault){observations++;if(!pass){fprintf(stderr,"mixed-stack-arguments slot=%u seed=%u observation=%zu fault=%u\n",slot,seed,observations,fault);exit(1);}}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;size_t page=(size_t)sysconf(_SC_PAGESIZE);
 unsigned char *map=mmap(0,page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_NONE))return 2;unsigned char *input=map+page-16;
 const uint64_t payloads[]={0,UINT64_C(0x8000000000000000),UINT64_C(0x80000000),UINT64_C(0x7f800000),UINT64_C(0x7fc12345),UINT64_C(0x7ff0000000000000),UINT64_C(0x7ff8123456789abc),UINT64_C(0x7ff0123456789abc),UINT64_MAX,1};
 for(unsigned slot=0;slot<count;slot++)for(unsigned seed=0;seed<256;seed++){
  memset(map,0xa5,page);u128 pair=((u128)(seed*UINT64_C(0x8123456789abcdef))<<64)|(seed*UINT64_C(0xf06dea67e461de5b));memcpy(input,&pair,16);
  uint64_t bits=payloads[seed%10],salt=(seed+slot*37)*UINT64_C(0x9e3779b97f4a7c15),fp0=cases[slot].kind==0?(uint32_t)bits:cases[slot].kind==1?bits:(uint64_t)pair,fp1=cases[slot].kind==2?(uint64_t)(pair>>64):0;
  uint64_t expected=model(prefix,pair,fp0,fp1,salt);calls=0;uint64_t actual=cases[slot].run(input,bits,salt);
  if(fault==1)actual^=1;if(fault==2)calls=0;if(fault==3)input[-1]^=1;
  check(calls==1,slot,seed,fault);check(actual==expected,slot,seed,fault);check(memcmp(input,&pair,16)==0,slot,seed,fault);int guard=1;for(size_t i=0;i<page-16;i++)guard&=map[i]==0xa5;check(guard,slot,seed,fault);
 }
 if(munmap(map,page*2)||count!=6||observations!=6144)return 2;printf("mixed-stack-arguments observations=%zu ccc-fastcc=scalar-fp-vector128=stack-gp128=alignment-holes=live-suffixes=llvm-c-interop=guard-pages=preserved\n",observations);return 0;
}
extern uint64_t mixed_stack_probe_0(const void *,uint64_t,uint64_t);
uint64_t mixed_stack_provider_0(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t p6,float fp,u128 pair,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5,p6},raw[2]={0,0};memcpy(raw,&fp,sizeof fp);calls++;return model(pre,pair,raw[0],raw[1],salt);}
extern uint64_t mixed_stack_probe_1(const void *,uint64_t,uint64_t);
uint64_t mixed_stack_provider_1(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t p6,double fp,u128 pair,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5,p6},raw[2]={0,0};memcpy(raw,&fp,sizeof fp);calls++;return model(pre,pair,raw[0],raw[1],salt);}
extern uint64_t mixed_stack_probe_2(const void *,uint64_t,uint64_t);
uint64_t mixed_stack_provider_2(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t p6,Carrier fp,u128 pair,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5,p6},raw[2]={0,0};memcpy(raw,&fp,sizeof fp);calls++;return model(pre,pair,raw[0],raw[1],salt);}
extern uint64_t mixed_stack_probe_3(const void *,uint64_t,uint64_t);
uint64_t mixed_stack_provider_3(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t p6,float fp,u128 pair,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5,p6},raw[2]={0,0};memcpy(raw,&fp,sizeof fp);calls++;return model(pre,pair,raw[0],raw[1],salt);}
extern uint64_t mixed_stack_probe_4(const void *,uint64_t,uint64_t);
uint64_t mixed_stack_provider_4(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t p6,double fp,u128 pair,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5,p6},raw[2]={0,0};memcpy(raw,&fp,sizeof fp);calls++;return model(pre,pair,raw[0],raw[1],salt);}
extern uint64_t mixed_stack_probe_5(const void *,uint64_t,uint64_t);
uint64_t mixed_stack_provider_5(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t p6,Carrier fp,u128 pair,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5,p6},raw[2]={0,0};memcpy(raw,&fp,sizeof fp);calls++;return model(pre,pair,raw[0],raw[1],salt);}
static const struct test_case cases[]={
{0,mixed_stack_probe_0},
{1,mixed_stack_probe_1},
{2,mixed_stack_probe_2},
{0,mixed_stack_probe_3},
{1,mixed_stack_probe_4},
{2,mixed_stack_probe_5},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
