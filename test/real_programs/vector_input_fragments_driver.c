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
extern uint64_t vector_input_body_0(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt);
extern uint64_t vector_input_probe_0(void *,const void *,uint64_t);
uint64_t vector_input_provider_0(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);return digest(raw,32,8,pre,salt);}
static uint64_t vector_input_direct_0(const unsigned char *input,uint64_t salt){Carrier v[2];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);return vector_input_body_0(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],salt);}
extern uint64_t vector_input_body_1(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt);
extern uint64_t vector_input_probe_1(void *,const void *,uint64_t);
uint64_t vector_input_provider_1(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);return digest(raw,32,8,pre,salt);}
static uint64_t vector_input_direct_1(const unsigned char *input,uint64_t salt){Carrier v[2];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);return vector_input_body_1(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],salt);}
extern uint64_t vector_input_body_2(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt);
extern uint64_t vector_input_probe_2(void *,const void *,uint64_t);
uint64_t vector_input_provider_2(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);return digest(raw,64,8,pre,salt);}
static uint64_t vector_input_direct_2(const unsigned char *input,uint64_t salt){Carrier v[4];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);return vector_input_body_2(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],salt);}
extern uint64_t vector_input_body_3(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt);
extern uint64_t vector_input_probe_3(void *,const void *,uint64_t);
uint64_t vector_input_provider_3(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);return digest(raw,64,8,pre,salt);}
static uint64_t vector_input_direct_3(const unsigned char *input,uint64_t salt){Carrier v[4];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);return vector_input_body_3(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],salt);}
extern uint64_t vector_input_body_4(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt);
extern uint64_t vector_input_probe_4(void *,const void *,uint64_t);
uint64_t vector_input_provider_4(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);return digest(raw,16,16,pre,salt);}
static uint64_t vector_input_direct_4(const unsigned char *input,uint64_t salt){Carrier v[2];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);return vector_input_body_4(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],salt);}
extern uint64_t vector_input_body_5(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt);
extern uint64_t vector_input_probe_5(void *,const void *,uint64_t);
uint64_t vector_input_provider_5(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);return digest(raw,16,16,pre,salt);}
static uint64_t vector_input_direct_5(const unsigned char *input,uint64_t salt){Carrier v[2];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);return vector_input_body_5(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],salt);}
extern uint64_t vector_input_body_6(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt);
extern uint64_t vector_input_probe_6(void *,const void *,uint64_t);
uint64_t vector_input_provider_6(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);return digest(raw,32,16,pre,salt);}
static uint64_t vector_input_direct_6(const unsigned char *input,uint64_t salt){Carrier v[4];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);return vector_input_body_6(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],salt);}
extern uint64_t vector_input_body_7(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt);
extern uint64_t vector_input_probe_7(void *,const void *,uint64_t);
uint64_t vector_input_provider_7(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);return digest(raw,32,16,pre,salt);}
static uint64_t vector_input_direct_7(const unsigned char *input,uint64_t salt){Carrier v[4];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);return vector_input_body_7(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],salt);}
extern uint64_t vector_input_body_8(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt);
extern uint64_t vector_input_probe_8(void *,const void *,uint64_t);
uint64_t vector_input_provider_8(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);memcpy(raw+64,&v4,16);memcpy(raw+80,&v5,16);memcpy(raw+96,&v6,16);memcpy(raw+112,&v7,16);return digest(raw,64,16,pre,salt);}
static uint64_t vector_input_direct_8(const unsigned char *input,uint64_t salt){Carrier v[8];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);memcpy(&v[4],input+64,16);memcpy(&v[5],input+80,16);memcpy(&v[6],input+96,16);memcpy(&v[7],input+112,16);return vector_input_body_8(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7],salt);}
extern uint64_t vector_input_body_9(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt);
extern uint64_t vector_input_probe_9(void *,const void *,uint64_t);
uint64_t vector_input_provider_9(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);memcpy(raw+64,&v4,16);memcpy(raw+80,&v5,16);memcpy(raw+96,&v6,16);memcpy(raw+112,&v7,16);return digest(raw,64,16,pre,salt);}
static uint64_t vector_input_direct_9(const unsigned char *input,uint64_t salt){Carrier v[8];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);memcpy(&v[4],input+64,16);memcpy(&v[5],input+80,16);memcpy(&v[6],input+96,16);memcpy(&v[7],input+112,16);return vector_input_body_9(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7],salt);}
extern uint64_t vector_input_body_10(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt);
extern uint64_t vector_input_probe_10(void *,const void *,uint64_t);
uint64_t vector_input_provider_10(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);return digest(raw,8,32,pre,salt);}
static uint64_t vector_input_direct_10(const unsigned char *input,uint64_t salt){Carrier v[2];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);return vector_input_body_10(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],salt);}
extern uint64_t vector_input_body_11(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt);
extern uint64_t vector_input_probe_11(void *,const void *,uint64_t);
uint64_t vector_input_provider_11(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);return digest(raw,8,32,pre,salt);}
static uint64_t vector_input_direct_11(const unsigned char *input,uint64_t salt){Carrier v[2];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);return vector_input_body_11(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],salt);}
extern uint64_t vector_input_body_12(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt);
extern uint64_t vector_input_probe_12(void *,const void *,uint64_t);
uint64_t vector_input_provider_12(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);return digest(raw,16,32,pre,salt);}
static uint64_t vector_input_direct_12(const unsigned char *input,uint64_t salt){Carrier v[4];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);return vector_input_body_12(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],salt);}
extern uint64_t vector_input_body_13(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt);
extern uint64_t vector_input_probe_13(void *,const void *,uint64_t);
uint64_t vector_input_provider_13(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);return digest(raw,16,32,pre,salt);}
static uint64_t vector_input_direct_13(const unsigned char *input,uint64_t salt){Carrier v[4];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);return vector_input_body_13(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],salt);}
extern uint64_t vector_input_body_14(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt);
extern uint64_t vector_input_probe_14(void *,const void *,uint64_t);
uint64_t vector_input_provider_14(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);memcpy(raw+64,&v4,16);memcpy(raw+80,&v5,16);memcpy(raw+96,&v6,16);memcpy(raw+112,&v7,16);return digest(raw,32,32,pre,salt);}
static uint64_t vector_input_direct_14(const unsigned char *input,uint64_t salt){Carrier v[8];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);memcpy(&v[4],input+64,16);memcpy(&v[5],input+80,16);memcpy(&v[6],input+96,16);memcpy(&v[7],input+112,16);return vector_input_body_14(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7],salt);}
extern uint64_t vector_input_body_15(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt);
extern uint64_t vector_input_probe_15(void *,const void *,uint64_t);
uint64_t vector_input_provider_15(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);memcpy(raw+64,&v4,16);memcpy(raw+80,&v5,16);memcpy(raw+96,&v6,16);memcpy(raw+112,&v7,16);return digest(raw,32,32,pre,salt);}
static uint64_t vector_input_direct_15(const unsigned char *input,uint64_t salt){Carrier v[8];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);memcpy(&v[4],input+64,16);memcpy(&v[5],input+80,16);memcpy(&v[6],input+96,16);memcpy(&v[7],input+112,16);return vector_input_body_15(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7],salt);}
extern uint64_t vector_input_body_16(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt);
extern uint64_t vector_input_probe_16(void *,const void *,uint64_t);
uint64_t vector_input_provider_16(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);return digest(raw,4,64,pre,salt);}
static uint64_t vector_input_direct_16(const unsigned char *input,uint64_t salt){Carrier v[2];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);return vector_input_body_16(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],salt);}
extern uint64_t vector_input_body_17(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt);
extern uint64_t vector_input_probe_17(void *,const void *,uint64_t);
uint64_t vector_input_provider_17(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);return digest(raw,4,64,pre,salt);}
static uint64_t vector_input_direct_17(const unsigned char *input,uint64_t salt){Carrier v[2];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);return vector_input_body_17(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],salt);}
extern uint64_t vector_input_body_18(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt);
extern uint64_t vector_input_probe_18(void *,const void *,uint64_t);
uint64_t vector_input_provider_18(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);return digest(raw,8,64,pre,salt);}
static uint64_t vector_input_direct_18(const unsigned char *input,uint64_t salt){Carrier v[4];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);return vector_input_body_18(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],salt);}
extern uint64_t vector_input_body_19(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt);
extern uint64_t vector_input_probe_19(void *,const void *,uint64_t);
uint64_t vector_input_provider_19(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);return digest(raw,8,64,pre,salt);}
static uint64_t vector_input_direct_19(const unsigned char *input,uint64_t salt){Carrier v[4];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);return vector_input_body_19(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],salt);}
extern uint64_t vector_input_body_20(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt);
extern uint64_t vector_input_probe_20(void *,const void *,uint64_t);
uint64_t vector_input_provider_20(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);memcpy(raw+64,&v4,16);memcpy(raw+80,&v5,16);memcpy(raw+96,&v6,16);memcpy(raw+112,&v7,16);return digest(raw,16,64,pre,salt);}
static uint64_t vector_input_direct_20(const unsigned char *input,uint64_t salt){Carrier v[8];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);memcpy(&v[4],input+64,16);memcpy(&v[5],input+80,16);memcpy(&v[6],input+96,16);memcpy(&v[7],input+112,16);return vector_input_body_20(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7],salt);}
extern uint64_t vector_input_body_21(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt);
extern uint64_t vector_input_probe_21(void *,const void *,uint64_t);
uint64_t vector_input_provider_21(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,Carrier v0,Carrier v1,Carrier v2,Carrier v3,Carrier v4,Carrier v5,Carrier v6,Carrier v7,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,16);memcpy(raw+16,&v1,16);memcpy(raw+32,&v2,16);memcpy(raw+48,&v3,16);memcpy(raw+64,&v4,16);memcpy(raw+80,&v5,16);memcpy(raw+96,&v6,16);memcpy(raw+112,&v7,16);return digest(raw,16,64,pre,salt);}
static uint64_t vector_input_direct_21(const unsigned char *input,uint64_t salt){Carrier v[8];memcpy(&v[0],input+0,16);memcpy(&v[1],input+16,16);memcpy(&v[2],input+32,16);memcpy(&v[3],input+48,16);memcpy(&v[4],input+64,16);memcpy(&v[5],input+80,16);memcpy(&v[6],input+96,16);memcpy(&v[7],input+112,16);return vector_input_body_21(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7],salt);}
extern uint64_t vector_input_body_22(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt);
extern uint64_t vector_input_probe_22(void *,const void *,uint64_t);
uint64_t vector_input_provider_22(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,1);memcpy(raw+1,&v1,1);memcpy(raw+2,&v2,1);return digest(raw,3,8,pre,salt);}
static uint64_t vector_input_direct_22(const unsigned char *input,uint64_t salt){uint64_t v[3];v[0]=word(input+0,1)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(255));v[1]=word(input+1,1)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(255));v[2]=word(input+2,1)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(255));return vector_input_body_22(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],salt);}
extern uint64_t vector_input_body_23(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt);
extern uint64_t vector_input_probe_23(void *,const void *,uint64_t);
uint64_t vector_input_provider_23(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,1);memcpy(raw+1,&v1,1);memcpy(raw+2,&v2,1);return digest(raw,3,8,pre,salt);}
static uint64_t vector_input_direct_23(const unsigned char *input,uint64_t salt){uint64_t v[3];v[0]=word(input+0,1)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(255));v[1]=word(input+1,1)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(255));v[2]=word(input+2,1)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(255));return vector_input_body_23(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],salt);}
extern uint64_t vector_input_body_24(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt);
extern uint64_t vector_input_probe_24(void *,const void *,uint64_t);
uint64_t vector_input_provider_24(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,2);memcpy(raw+2,&v1,2);memcpy(raw+4,&v2,2);return digest(raw,3,16,pre,salt);}
static uint64_t vector_input_direct_24(const unsigned char *input,uint64_t salt){uint64_t v[3];v[0]=word(input+0,2)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(65535));v[1]=word(input+2,2)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(65535));v[2]=word(input+4,2)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(65535));return vector_input_body_24(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],salt);}
extern uint64_t vector_input_body_25(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt);
extern uint64_t vector_input_probe_25(void *,const void *,uint64_t);
uint64_t vector_input_provider_25(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,2);memcpy(raw+2,&v1,2);memcpy(raw+4,&v2,2);return digest(raw,3,16,pre,salt);}
static uint64_t vector_input_direct_25(const unsigned char *input,uint64_t salt){uint64_t v[3];v[0]=word(input+0,2)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(65535));v[1]=word(input+2,2)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(65535));v[2]=word(input+4,2)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(65535));return vector_input_body_25(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],salt);}
extern uint64_t vector_input_body_26(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt);
extern uint64_t vector_input_probe_26(void *,const void *,uint64_t);
uint64_t vector_input_provider_26(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,8);memcpy(raw+8,&v1,8);memcpy(raw+16,&v2,8);return digest(raw,3,64,pre,salt);}
static uint64_t vector_input_direct_26(const unsigned char *input,uint64_t salt){uint64_t v[3];v[0]=word(input+0,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));v[1]=word(input+8,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));v[2]=word(input+16,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));return vector_input_body_26(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],salt);}
extern uint64_t vector_input_body_27(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt);
extern uint64_t vector_input_probe_27(void *,const void *,uint64_t);
uint64_t vector_input_provider_27(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,8);memcpy(raw+8,&v1,8);memcpy(raw+16,&v2,8);return digest(raw,3,64,pre,salt);}
static uint64_t vector_input_direct_27(const unsigned char *input,uint64_t salt){uint64_t v[3];v[0]=word(input+0,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));v[1]=word(input+8,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));v[2]=word(input+16,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));return vector_input_body_27(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],salt);}
extern uint64_t vector_input_body_28(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t v3,uint64_t v4,uint64_t salt);
extern uint64_t vector_input_probe_28(void *,const void *,uint64_t);
uint64_t vector_input_provider_28(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t v3,uint64_t v4,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,4);memcpy(raw+4,&v1,4);memcpy(raw+8,&v2,4);memcpy(raw+12,&v3,4);memcpy(raw+16,&v4,4);return digest(raw,5,32,pre,salt);}
static uint64_t vector_input_direct_28(const unsigned char *input,uint64_t salt){uint64_t v[5];v[0]=word(input+0,4)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(4294967295));v[1]=word(input+4,4)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(4294967295));v[2]=word(input+8,4)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(4294967295));v[3]=word(input+12,4)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(4294967295));v[4]=word(input+16,4)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(4294967295));return vector_input_body_28(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],v[4],salt);}
extern uint64_t vector_input_body_29(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t v3,uint64_t v4,uint64_t salt);
extern uint64_t vector_input_probe_29(void *,const void *,uint64_t);
uint64_t vector_input_provider_29(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t v3,uint64_t v4,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,4);memcpy(raw+4,&v1,4);memcpy(raw+8,&v2,4);memcpy(raw+12,&v3,4);memcpy(raw+16,&v4,4);return digest(raw,5,32,pre,salt);}
static uint64_t vector_input_direct_29(const unsigned char *input,uint64_t salt){uint64_t v[5];v[0]=word(input+0,4)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(4294967295));v[1]=word(input+4,4)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(4294967295));v[2]=word(input+8,4)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(4294967295));v[3]=word(input+12,4)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(4294967295));v[4]=word(input+16,4)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(4294967295));return vector_input_body_29(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],v[3],v[4],salt);}
extern uint64_t vector_input_body_30(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt);
extern uint64_t vector_input_probe_30(void *,const void *,uint64_t);
uint64_t vector_input_provider_30(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,8);memcpy(raw+8,&v1,8);memcpy(raw+16,&v2,8);return digest(raw,3,64,pre,salt);}
static uint64_t vector_input_direct_30(const unsigned char *input,uint64_t salt){uint64_t v[3];v[0]=word(input+0,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));v[1]=word(input+8,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));v[2]=word(input+16,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));return vector_input_body_30(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],salt);}
extern uint64_t vector_input_body_31(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt);
extern uint64_t vector_input_probe_31(void *,const void *,uint64_t);
uint64_t vector_input_provider_31(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,uint64_t v0,uint64_t v1,uint64_t v2,uint64_t salt){uint64_t pre[]={p0,p1,p2,p3,p4,p5};unsigned char raw[128];memcpy(raw+0,&v0,8);memcpy(raw+8,&v1,8);memcpy(raw+16,&v2,8);return digest(raw,3,64,pre,salt);}
static uint64_t vector_input_direct_31(const unsigned char *input,uint64_t salt){uint64_t v[3];v[0]=word(input+0,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));v[1]=word(input+8,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));v[2]=word(input+16,8)|((salt^UINT64_C(0xabcd0123456789ef))&~UINT64_C(18446744073709551615));return vector_input_body_31(prefix[0],prefix[1],prefix[2],prefix[3],prefix[4],prefix[5],v[0],v[1],v[2],salt);}
static const struct test_case cases[]={
{32,8,0,vector_input_direct_0,vector_input_probe_0},
{32,8,0,vector_input_direct_1,vector_input_probe_1},
{64,8,0,vector_input_direct_2,vector_input_probe_2},
{64,8,0,vector_input_direct_3,vector_input_probe_3},
{16,16,0,vector_input_direct_4,vector_input_probe_4},
{16,16,0,vector_input_direct_5,vector_input_probe_5},
{32,16,0,vector_input_direct_6,vector_input_probe_6},
{32,16,0,vector_input_direct_7,vector_input_probe_7},
{64,16,0,vector_input_direct_8,vector_input_probe_8},
{64,16,0,vector_input_direct_9,vector_input_probe_9},
{8,32,0,vector_input_direct_10,vector_input_probe_10},
{8,32,0,vector_input_direct_11,vector_input_probe_11},
{16,32,0,vector_input_direct_12,vector_input_probe_12},
{16,32,0,vector_input_direct_13,vector_input_probe_13},
{32,32,0,vector_input_direct_14,vector_input_probe_14},
{32,32,0,vector_input_direct_15,vector_input_probe_15},
{4,64,0,vector_input_direct_16,vector_input_probe_16},
{4,64,0,vector_input_direct_17,vector_input_probe_17},
{8,64,0,vector_input_direct_18,vector_input_probe_18},
{8,64,0,vector_input_direct_19,vector_input_probe_19},
{16,64,0,vector_input_direct_20,vector_input_probe_20},
{16,64,0,vector_input_direct_21,vector_input_probe_21},
{3,8,0,vector_input_direct_22,vector_input_probe_22},
{3,8,0,vector_input_direct_23,vector_input_probe_23},
{3,16,0,vector_input_direct_24,vector_input_probe_24},
{3,16,0,vector_input_direct_25,vector_input_probe_25},
{3,64,0,vector_input_direct_26,vector_input_probe_26},
{3,64,0,vector_input_direct_27,vector_input_probe_27},
{5,32,0,vector_input_direct_28,vector_input_probe_28},
{5,32,0,vector_input_direct_29,vector_input_probe_29},
{3,64,1,vector_input_direct_30,vector_input_probe_30},
{3,64,1,vector_input_direct_31,vector_input_probe_31},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
