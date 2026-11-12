#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef unsigned __int128 u128;
typedef uint64_t v128 __attribute__((vector_size(16)));
typedef v128 (*body_fn)(v128,v128);
typedef uint64_t (*probe_fn)(void *,const void *,const void *,uint64_t);
struct abi_case{unsigned n,bits;probe_fn probe;body_fn body;};
static uint64_t lane_mask(unsigned bits){return (UINT64_C(1)<<bits)-1;}
static __attribute__((noinline)) v128 raw_model(v128 x,v128 y,unsigned n,unsigned bits){
 uint64_t a[2],b[2],out[2]={0,0};memcpy(a,&x,16);memcpy(b,&y,16);unsigned stride=n==3?32:128/n;uint64_t mask=lane_mask(bits);
 for(unsigned i=0;i<n;i++){unsigned word=i*stride/64,shift=i*stride%64;uint64_t value=(((a[word]>>shift)&mask)+((b[word]>>shift)&mask))&mask;out[word]|=value<<shift;}
 v128 result;memcpy(&result,out,16);return result;
}
static v128 raw_input(const unsigned char *p,unsigned n,unsigned bits,uint64_t seed){
 u128 dense=0;memcpy(&dense,p,(n*bits+7)/8);uint64_t out[2]={seed,~seed};unsigned stride=n==3?32:128/n;uint64_t mask=lane_mask(bits);
 for(unsigned i=0;i<n;i++){unsigned word=i*stride/64,shift=i*stride%64;out[word]=(out[word]&~(mask<<shift))|((uint64_t)(dense>>(i*bits))&mask)<<shift;}
 v128 result;memcpy(&result,out,16);return result;
}
static int raw_equal(v128 x,v128 y,unsigned n,unsigned bits){uint64_t a[2],b[2];memcpy(a,&x,16);memcpy(b,&y,16);unsigned stride=n==3?32:128/n;uint64_t mask=lane_mask(bits);for(unsigned i=0;i<n;i++){unsigned word=i*stride/64,shift=i*stride%64;if(((a[word]>>shift)&mask)!=((b[word]>>shift)&mask))return 0;}return 1;}
static u128 dense_model(const unsigned char *ap,const unsigned char *bp,unsigned n,unsigned bits){u128 a=0,b=0,result=0;unsigned bytes=(n*bits+7)/8;memcpy(&a,ap,bytes);memcpy(&b,bp,bytes);u128 mask=lane_mask(bits);for(unsigned i=0;i<n;i++)result|=((((a>>(i*bits))&mask)+((b>>(i*bits))&mask))&mask)<<(i*bits);return result;}
static int dense_equal(const unsigned char *p,u128 expected,unsigned n,unsigned bits){u128 actual=0;memcpy(&actual,p,(n*bits+7)/8);return ((actual^expected)&(((u128)1<<(n*bits))-1))==0;}
static size_t observations;
static void check(int pass,unsigned slot,unsigned n,unsigned bits,unsigned seed,unsigned fault){observations++;if(!pass){fprintf(stderr,"promoted-vector-abi slot=%u n=%u bits=%u seed=%u observation=%zu fault=%u\n",slot,n,bits,seed,observations,fault);exit(1);}}
static int run_all(const struct abi_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;size_t page=(size_t)sysconf(_SC_PAGESIZE);unsigned char *map=mmap(0,page*4,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_NONE)||mprotect(map+3*page,page,PROT_NONE))return 2;
 for(unsigned slot=0;slot<count;slot++){unsigned n=cases[slot].n,bits=cases[slot].bits,bytes=(n*bits+7)/8;for(unsigned seed=0;seed<64;seed++){
  unsigned char *ap=map+page-bytes,*bp=map+3*page-bytes,sa[16],sb[16];for(unsigned i=0;i<bytes;i++){ap[i]=(unsigned char)((seed*73+i*131)^(slot*19+255));bp[i]=(unsigned char)((seed*31+i*29)^(slot*43+71));}memcpy(sa,ap,bytes);memcpy(sb,bp,bytes);
  v128 x=raw_input(ap,n,bits,seed*UINT64_C(0x8123456789abcdef)),y=raw_input(bp,n,bits,seed*UINT64_C(0x9e3779b97f4a7c15));v128 raw=cases[slot].body(x,y);check(raw_equal(raw,raw_model(x,y,n,bits),n,bits),slot,n,bits,seed,fault);
  struct{unsigned char pre[9],data[32],post[9];}out;memset(&out,0xa5,sizeof out);uint64_t salt=(seed+slot*37)*UINT64_C(0xf06dea67e461de5b);uint64_t returned=cases[slot].probe(out.data,ap,bp,salt);if(fault==1)returned^=1;if(fault==2)out.data[0]^=1;if(fault==3)out.post[0]^=1;u128 expected=dense_model(ap,bp,n,bits);
  check(returned==(salt^90),slot,n,bits,seed,fault);check(dense_equal(out.data,expected,n,bits),slot,n,bits,seed,fault);check(dense_equal(out.data+16,expected,n,bits),slot,n,bits,seed,fault);
  int pre=1,post=1,gap0=1,gap1=1;for(unsigned i=0;i<9;i++){pre&=out.pre[i]==0xa5;post&=out.post[i]==0xa5;}for(unsigned i=bytes;i<16;i++){gap0&=out.data[i]==0xa5;gap1&=out.data[i+16]==0xa5;}
  check(pre,slot,n,bits,seed,fault);check(post,slot,n,bits,seed,fault);check(gap0,slot,n,bits,seed,fault);check(gap1,slot,n,bits,seed,fault);check(memcmp(ap,sa,bytes)==0,slot,n,bits,seed,fault);check(memcmp(bp,sb,bytes)==0,slot,n,bits,seed,fault);
 }}
 if(munmap(map,page*4)||count!=2||observations!=1280)return 2;printf("promoted-vector-abi observations=%zu llvm-c-local-interop=ccc-fastcc=expanded-cells=dirty-bits=exact-stores=guard-pages=preserved\n",observations);return 0;
}
extern v128 promoted_body_3_32_c(v128,v128);
extern uint64_t promoted_probe_3_32_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_3_32_c(v128 x,v128 y){return raw_model(x,y,3,32);}
extern v128 promoted_body_3_32_fast(v128,v128);
extern uint64_t promoted_probe_3_32_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_3_32_fast(v128 x,v128 y){return raw_model(x,y,3,32);}
static const struct abi_case cases[]={
{3,32,promoted_probe_3_32_c,promoted_body_3_32_c},
{3,32,promoted_probe_3_32_fast,promoted_body_3_32_fast},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
