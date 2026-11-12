#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t Carrier __attribute__((vector_size(16)));
typedef uint64_t (*direct_fn)(const unsigned char *,uint64_t);
typedef uint64_t (*probe_fn)(void *,const void *,uint64_t);
struct test_case{unsigned n,bits,pointer;direct_fn direct;probe_fn probe;};
static const uint64_t prefix[]={UINT64_C(0x123456789abcdef0),UINT64_C(0xfedcba9876543210),UINT64_C(0x1122334455667788),UINT64_C(0xabcd0123456789ef),UINT64_C(0x87654321fedcba98),UINT64_C(0x1020304050607080)};
static uint64_t word(const unsigned char *p,unsigned bytes){uint64_t value=0;for(unsigned i=0;i<bytes;i++)value|=(uint64_t)p[i]<<(8*i);return value;}
static uint64_t digest(const unsigned char *p,unsigned n,unsigned bits,const uint64_t *pre,uint64_t salt){for(unsigned i=0;i<6;i++)salt^=pre[i];for(unsigned i=0;i<n;i++)salt=salt*UINT64_C(1099511628211)^word(p+i*(bits/8),bits/8);return salt;}
static volatile uint64_t void_hash;
static volatile unsigned void_count;
void vector_input_void_provider(Carrier a,Carrier b){unsigned char raw[32];uint64_t zero[6]={0};memcpy(raw,&a,16);memcpy(raw+16,&b,16);void_hash=digest(raw,8,32,zero,0);void_count++;}
extern void vector_input_void_probe(const void *);
static size_t observations;
static void check(int pass,unsigned slot,unsigned seed,unsigned fault){observations++;if(!pass){fprintf(stderr,"vector-input-fragments slot=%u seed=%u observation=%zu fault=%u\n",slot,seed,observations,fault);exit(1);}}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;size_t page=(size_t)sysconf(_SC_PAGESIZE);
 unsigned char *map=mmap(0,page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_NONE))return 2;
 for(unsigned slot=0;slot<count;slot++)for(unsigned seed=0;seed<64;seed++){
  unsigned extent=cases[slot].n*(cases[slot].bits/8);unsigned char *input=map+page-extent,copy[128];memset(map,0xa5,page);
  for(unsigned i=0;i<extent;i++)input[i]=(unsigned char)(((i+seed*31)*173)^0xa5);
  if(cases[slot].pointer)for(unsigned i=0;i<cases[slot].n;i++){uintptr_t pointer=(uintptr_t)(map+((seed*64+i*8)%(page-128)));memcpy(input+i*8,&pointer,8);}
  memcpy(copy,input,extent);uint64_t salt=(seed+slot*37)*UINT64_C(0xf06dea67e461de5b),expected=digest(input,cases[slot].n,cases[slot].bits,prefix,salt);
  check(cases[slot].direct(input,salt)==expected,slot,seed,fault);
  struct{unsigned char pre[9],data[16],post[9];}out;memset(&out,0xa5,sizeof out);uint64_t result=cases[slot].probe(out.data,input,salt);
  if(fault==1)result^=1;if(fault==2)out.data[0]^=1;if(fault==3)out.post[0]^=1;
  uint64_t local,external;memcpy(&local,out.data,8);memcpy(&external,out.data+8,8);
  check(result==(salt^90),slot,seed,fault);check(local==expected,slot,seed,fault);check(external==expected,slot,seed,fault);
  int pre=1,post=1;for(unsigned i=0;i<9;i++){pre&=out.pre[i]==0xa5;post&=out.post[i]==0xa5;}check(pre,slot,seed,fault);check(post,slot,seed,fault);check(memcmp(copy,input,extent)==0,slot,seed,fault);
 }
 for(unsigned seed=0;seed<64;seed++){unsigned char *input=map+page-32,copy[32];for(unsigned i=0;i<32;i++)input[i]=(unsigned char)((seed*31+i)*173);memcpy(copy,input,32);uint64_t zero[6]={0};void_count=0;void_hash=0;vector_input_void_probe(input);check(void_count==1&&void_hash==digest(input,8,32,zero,0),32,seed,fault);check(memcmp(copy,input,32)==0,32,seed,fault);}
 if(munmap(map,page*2)||count!=32||observations!=14464)return 2;printf("vector-input-fragments observations=%zu ccc-fastcc=split-xmm=scalar-gp=live-prefixes=stack-words=llvm-c-local-interop=void-call=guard-pages=preserved\n",observations);return 0;
}
