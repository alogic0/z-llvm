#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*body_fn)(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
typedef uint64_t (*probe_fn)(void *,const void *,uint64_t);
struct test_case{unsigned index;body_fn body;probe_fn probe;};
static uint64_t model(const uint64_t *args,unsigned index){uint32_t bits=(uint32_t)args[index];int32_t signed_bits;memcpy(&signed_bits,&bits,4);uint64_t hash=(uint64_t)(int64_t)signed_bits;for(unsigned i=0;i<6;i++)hash=hash*UINT64_C(1099511628211)^args[i];return hash;}
static size_t observations;
static void check(int pass,unsigned slot,unsigned seed,unsigned fault){observations++;if(!pass){fprintf(stderr,"sign-extension-live slot=%u seed=%u observation=%zu fault=%u\n",slot,seed,observations,fault);exit(1);}}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;size_t page=(size_t)sysconf(_SC_PAGESIZE);
 unsigned char *map=mmap(0,page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_NONE))return 2;unsigned char *input=map+page-48;
 const uint64_t values[]={0,1,UINT64_C(0x80000000),UINT64_C(0xffffffff),UINT64_C(0x8000000000000000),UINT64_MAX,UINT64_C(0x123456789abcdef0),UINT64_C(0xfedcba9876543210)};
 for(unsigned slot=0;slot<count;slot++)for(unsigned seed=0;seed<256;seed++){
  uint64_t args[6];for(unsigned i=0;i<6;i++)args[i]=values[(seed+i)%8]^(seed<8?0:(seed*UINT64_C(0xf06dea67e461de5b)&UINT64_C(0xffffffff00000000)));memcpy(input,args,48);
  uint64_t expected=model(args,cases[slot].index),salt=(seed+slot*37)*UINT64_C(0x9e3779b97f4a7c15);check(cases[slot].body(args[0],args[1],args[2],args[3],args[4],args[5])==expected,slot,seed,fault);
  struct{unsigned char pre[9],data[16],post[9];}out;memset(&out,0xa5,sizeof out);uint64_t returned=cases[slot].probe(out.data,input,salt);if(fault==1)returned^=1;if(fault==2)out.data[0]^=1;if(fault==3)out.post[0]^=1;
  uint64_t local,external;memcpy(&local,out.data,8);memcpy(&external,out.data+8,8);check(returned==(salt^90),slot,seed,fault);check(local==expected,slot,seed,fault);check(external==expected,slot,seed,fault);
  int pre=1,post=1;for(unsigned i=0;i<9;i++){pre&=out.pre[i]==0xa5;post&=out.post[i]==0xa5;}check(pre,slot,seed,fault);check(post,slot,seed,fault);check(memcmp(input,args,48)==0,slot,seed,fault);
 }
 if(munmap(map,page*2)||count!=12||observations!=21504)return 2;printf("sign-extension-live observations=%zu six-gp-sources=full-width-aliases=phi-edges=llvm-c-local-interop=exact-stores=guard-pages=preserved\n",observations);return 0;
}
