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
 if(munmap(map,page*4)||count!=116||observations!=74240)return 2;printf("promoted-vector-abi observations=%zu llvm-c-local-interop=ccc-fastcc=expanded-cells=dirty-bits=exact-stores=guard-pages=preserved\n",observations);return 0;
}
extern v128 promoted_body_2_1_c(v128,v128);
extern uint64_t promoted_probe_2_1_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_1_c(v128 x,v128 y){return raw_model(x,y,2,1);}
extern v128 promoted_body_2_1_fast(v128,v128);
extern uint64_t promoted_probe_2_1_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_1_fast(v128 x,v128 y){return raw_model(x,y,2,1);}
extern v128 promoted_body_2_2_c(v128,v128);
extern uint64_t promoted_probe_2_2_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_2_c(v128 x,v128 y){return raw_model(x,y,2,2);}
extern v128 promoted_body_2_2_fast(v128,v128);
extern uint64_t promoted_probe_2_2_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_2_fast(v128 x,v128 y){return raw_model(x,y,2,2);}
extern v128 promoted_body_2_3_c(v128,v128);
extern uint64_t promoted_probe_2_3_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_3_c(v128 x,v128 y){return raw_model(x,y,2,3);}
extern v128 promoted_body_2_3_fast(v128,v128);
extern uint64_t promoted_probe_2_3_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_3_fast(v128 x,v128 y){return raw_model(x,y,2,3);}
extern v128 promoted_body_2_4_c(v128,v128);
extern uint64_t promoted_probe_2_4_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_4_c(v128 x,v128 y){return raw_model(x,y,2,4);}
extern v128 promoted_body_2_4_fast(v128,v128);
extern uint64_t promoted_probe_2_4_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_4_fast(v128 x,v128 y){return raw_model(x,y,2,4);}
extern v128 promoted_body_2_5_c(v128,v128);
extern uint64_t promoted_probe_2_5_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_5_c(v128 x,v128 y){return raw_model(x,y,2,5);}
extern v128 promoted_body_2_5_fast(v128,v128);
extern uint64_t promoted_probe_2_5_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_5_fast(v128 x,v128 y){return raw_model(x,y,2,5);}
extern v128 promoted_body_2_6_c(v128,v128);
extern uint64_t promoted_probe_2_6_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_6_c(v128 x,v128 y){return raw_model(x,y,2,6);}
extern v128 promoted_body_2_6_fast(v128,v128);
extern uint64_t promoted_probe_2_6_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_6_fast(v128 x,v128 y){return raw_model(x,y,2,6);}
extern v128 promoted_body_2_7_c(v128,v128);
extern uint64_t promoted_probe_2_7_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_7_c(v128 x,v128 y){return raw_model(x,y,2,7);}
extern v128 promoted_body_2_7_fast(v128,v128);
extern uint64_t promoted_probe_2_7_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_7_fast(v128 x,v128 y){return raw_model(x,y,2,7);}
extern v128 promoted_body_2_9_c(v128,v128);
extern uint64_t promoted_probe_2_9_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_9_c(v128 x,v128 y){return raw_model(x,y,2,9);}
extern v128 promoted_body_2_9_fast(v128,v128);
extern uint64_t promoted_probe_2_9_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_9_fast(v128 x,v128 y){return raw_model(x,y,2,9);}
extern v128 promoted_body_2_10_c(v128,v128);
extern uint64_t promoted_probe_2_10_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_10_c(v128 x,v128 y){return raw_model(x,y,2,10);}
extern v128 promoted_body_2_10_fast(v128,v128);
extern uint64_t promoted_probe_2_10_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_10_fast(v128 x,v128 y){return raw_model(x,y,2,10);}
extern v128 promoted_body_2_11_c(v128,v128);
extern uint64_t promoted_probe_2_11_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_11_c(v128 x,v128 y){return raw_model(x,y,2,11);}
extern v128 promoted_body_2_11_fast(v128,v128);
extern uint64_t promoted_probe_2_11_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_11_fast(v128 x,v128 y){return raw_model(x,y,2,11);}
extern v128 promoted_body_2_12_c(v128,v128);
extern uint64_t promoted_probe_2_12_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_12_c(v128 x,v128 y){return raw_model(x,y,2,12);}
extern v128 promoted_body_2_12_fast(v128,v128);
extern uint64_t promoted_probe_2_12_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_12_fast(v128 x,v128 y){return raw_model(x,y,2,12);}
extern v128 promoted_body_2_13_c(v128,v128);
extern uint64_t promoted_probe_2_13_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_13_c(v128 x,v128 y){return raw_model(x,y,2,13);}
extern v128 promoted_body_2_13_fast(v128,v128);
extern uint64_t promoted_probe_2_13_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_13_fast(v128 x,v128 y){return raw_model(x,y,2,13);}
extern v128 promoted_body_2_14_c(v128,v128);
extern uint64_t promoted_probe_2_14_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_14_c(v128 x,v128 y){return raw_model(x,y,2,14);}
extern v128 promoted_body_2_14_fast(v128,v128);
extern uint64_t promoted_probe_2_14_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_14_fast(v128 x,v128 y){return raw_model(x,y,2,14);}
extern v128 promoted_body_2_15_c(v128,v128);
extern uint64_t promoted_probe_2_15_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_15_c(v128 x,v128 y){return raw_model(x,y,2,15);}
extern v128 promoted_body_2_15_fast(v128,v128);
extern uint64_t promoted_probe_2_15_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_15_fast(v128 x,v128 y){return raw_model(x,y,2,15);}
extern v128 promoted_body_2_17_c(v128,v128);
extern uint64_t promoted_probe_2_17_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_17_c(v128 x,v128 y){return raw_model(x,y,2,17);}
extern v128 promoted_body_2_17_fast(v128,v128);
extern uint64_t promoted_probe_2_17_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_17_fast(v128 x,v128 y){return raw_model(x,y,2,17);}
extern v128 promoted_body_2_18_c(v128,v128);
extern uint64_t promoted_probe_2_18_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_18_c(v128 x,v128 y){return raw_model(x,y,2,18);}
extern v128 promoted_body_2_18_fast(v128,v128);
extern uint64_t promoted_probe_2_18_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_18_fast(v128 x,v128 y){return raw_model(x,y,2,18);}
extern v128 promoted_body_2_19_c(v128,v128);
extern uint64_t promoted_probe_2_19_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_19_c(v128 x,v128 y){return raw_model(x,y,2,19);}
extern v128 promoted_body_2_19_fast(v128,v128);
extern uint64_t promoted_probe_2_19_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_19_fast(v128 x,v128 y){return raw_model(x,y,2,19);}
extern v128 promoted_body_2_20_c(v128,v128);
extern uint64_t promoted_probe_2_20_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_20_c(v128 x,v128 y){return raw_model(x,y,2,20);}
extern v128 promoted_body_2_20_fast(v128,v128);
extern uint64_t promoted_probe_2_20_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_20_fast(v128 x,v128 y){return raw_model(x,y,2,20);}
extern v128 promoted_body_2_21_c(v128,v128);
extern uint64_t promoted_probe_2_21_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_21_c(v128 x,v128 y){return raw_model(x,y,2,21);}
extern v128 promoted_body_2_21_fast(v128,v128);
extern uint64_t promoted_probe_2_21_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_21_fast(v128 x,v128 y){return raw_model(x,y,2,21);}
extern v128 promoted_body_2_22_c(v128,v128);
extern uint64_t promoted_probe_2_22_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_22_c(v128 x,v128 y){return raw_model(x,y,2,22);}
extern v128 promoted_body_2_22_fast(v128,v128);
extern uint64_t promoted_probe_2_22_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_22_fast(v128 x,v128 y){return raw_model(x,y,2,22);}
extern v128 promoted_body_2_23_c(v128,v128);
extern uint64_t promoted_probe_2_23_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_23_c(v128 x,v128 y){return raw_model(x,y,2,23);}
extern v128 promoted_body_2_23_fast(v128,v128);
extern uint64_t promoted_probe_2_23_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_23_fast(v128 x,v128 y){return raw_model(x,y,2,23);}
extern v128 promoted_body_2_24_c(v128,v128);
extern uint64_t promoted_probe_2_24_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_24_c(v128 x,v128 y){return raw_model(x,y,2,24);}
extern v128 promoted_body_2_24_fast(v128,v128);
extern uint64_t promoted_probe_2_24_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_24_fast(v128 x,v128 y){return raw_model(x,y,2,24);}
extern v128 promoted_body_2_25_c(v128,v128);
extern uint64_t promoted_probe_2_25_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_25_c(v128 x,v128 y){return raw_model(x,y,2,25);}
extern v128 promoted_body_2_25_fast(v128,v128);
extern uint64_t promoted_probe_2_25_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_25_fast(v128 x,v128 y){return raw_model(x,y,2,25);}
extern v128 promoted_body_2_26_c(v128,v128);
extern uint64_t promoted_probe_2_26_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_26_c(v128 x,v128 y){return raw_model(x,y,2,26);}
extern v128 promoted_body_2_26_fast(v128,v128);
extern uint64_t promoted_probe_2_26_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_26_fast(v128 x,v128 y){return raw_model(x,y,2,26);}
extern v128 promoted_body_2_27_c(v128,v128);
extern uint64_t promoted_probe_2_27_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_27_c(v128 x,v128 y){return raw_model(x,y,2,27);}
extern v128 promoted_body_2_27_fast(v128,v128);
extern uint64_t promoted_probe_2_27_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_27_fast(v128 x,v128 y){return raw_model(x,y,2,27);}
extern v128 promoted_body_2_28_c(v128,v128);
extern uint64_t promoted_probe_2_28_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_28_c(v128 x,v128 y){return raw_model(x,y,2,28);}
extern v128 promoted_body_2_28_fast(v128,v128);
extern uint64_t promoted_probe_2_28_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_28_fast(v128 x,v128 y){return raw_model(x,y,2,28);}
extern v128 promoted_body_2_29_c(v128,v128);
extern uint64_t promoted_probe_2_29_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_29_c(v128 x,v128 y){return raw_model(x,y,2,29);}
extern v128 promoted_body_2_29_fast(v128,v128);
extern uint64_t promoted_probe_2_29_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_29_fast(v128 x,v128 y){return raw_model(x,y,2,29);}
extern v128 promoted_body_2_30_c(v128,v128);
extern uint64_t promoted_probe_2_30_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_30_c(v128 x,v128 y){return raw_model(x,y,2,30);}
extern v128 promoted_body_2_30_fast(v128,v128);
extern uint64_t promoted_probe_2_30_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_30_fast(v128 x,v128 y){return raw_model(x,y,2,30);}
extern v128 promoted_body_2_31_c(v128,v128);
extern uint64_t promoted_probe_2_31_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_31_c(v128 x,v128 y){return raw_model(x,y,2,31);}
extern v128 promoted_body_2_31_fast(v128,v128);
extern uint64_t promoted_probe_2_31_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_31_fast(v128 x,v128 y){return raw_model(x,y,2,31);}
extern v128 promoted_body_2_33_c(v128,v128);
extern uint64_t promoted_probe_2_33_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_33_c(v128 x,v128 y){return raw_model(x,y,2,33);}
extern v128 promoted_body_2_33_fast(v128,v128);
extern uint64_t promoted_probe_2_33_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_33_fast(v128 x,v128 y){return raw_model(x,y,2,33);}
extern v128 promoted_body_2_34_c(v128,v128);
extern uint64_t promoted_probe_2_34_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_34_c(v128 x,v128 y){return raw_model(x,y,2,34);}
extern v128 promoted_body_2_34_fast(v128,v128);
extern uint64_t promoted_probe_2_34_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_34_fast(v128 x,v128 y){return raw_model(x,y,2,34);}
extern v128 promoted_body_2_35_c(v128,v128);
extern uint64_t promoted_probe_2_35_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_35_c(v128 x,v128 y){return raw_model(x,y,2,35);}
extern v128 promoted_body_2_35_fast(v128,v128);
extern uint64_t promoted_probe_2_35_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_35_fast(v128 x,v128 y){return raw_model(x,y,2,35);}
extern v128 promoted_body_2_36_c(v128,v128);
extern uint64_t promoted_probe_2_36_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_36_c(v128 x,v128 y){return raw_model(x,y,2,36);}
extern v128 promoted_body_2_36_fast(v128,v128);
extern uint64_t promoted_probe_2_36_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_36_fast(v128 x,v128 y){return raw_model(x,y,2,36);}
extern v128 promoted_body_2_37_c(v128,v128);
extern uint64_t promoted_probe_2_37_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_37_c(v128 x,v128 y){return raw_model(x,y,2,37);}
extern v128 promoted_body_2_37_fast(v128,v128);
extern uint64_t promoted_probe_2_37_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_37_fast(v128 x,v128 y){return raw_model(x,y,2,37);}
extern v128 promoted_body_2_38_c(v128,v128);
extern uint64_t promoted_probe_2_38_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_38_c(v128 x,v128 y){return raw_model(x,y,2,38);}
extern v128 promoted_body_2_38_fast(v128,v128);
extern uint64_t promoted_probe_2_38_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_38_fast(v128 x,v128 y){return raw_model(x,y,2,38);}
extern v128 promoted_body_2_39_c(v128,v128);
extern uint64_t promoted_probe_2_39_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_39_c(v128 x,v128 y){return raw_model(x,y,2,39);}
extern v128 promoted_body_2_39_fast(v128,v128);
extern uint64_t promoted_probe_2_39_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_39_fast(v128 x,v128 y){return raw_model(x,y,2,39);}
extern v128 promoted_body_2_40_c(v128,v128);
extern uint64_t promoted_probe_2_40_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_40_c(v128 x,v128 y){return raw_model(x,y,2,40);}
extern v128 promoted_body_2_40_fast(v128,v128);
extern uint64_t promoted_probe_2_40_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_40_fast(v128 x,v128 y){return raw_model(x,y,2,40);}
extern v128 promoted_body_2_41_c(v128,v128);
extern uint64_t promoted_probe_2_41_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_41_c(v128 x,v128 y){return raw_model(x,y,2,41);}
extern v128 promoted_body_2_41_fast(v128,v128);
extern uint64_t promoted_probe_2_41_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_41_fast(v128 x,v128 y){return raw_model(x,y,2,41);}
extern v128 promoted_body_2_42_c(v128,v128);
extern uint64_t promoted_probe_2_42_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_42_c(v128 x,v128 y){return raw_model(x,y,2,42);}
extern v128 promoted_body_2_42_fast(v128,v128);
extern uint64_t promoted_probe_2_42_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_42_fast(v128 x,v128 y){return raw_model(x,y,2,42);}
extern v128 promoted_body_2_43_c(v128,v128);
extern uint64_t promoted_probe_2_43_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_43_c(v128 x,v128 y){return raw_model(x,y,2,43);}
extern v128 promoted_body_2_43_fast(v128,v128);
extern uint64_t promoted_probe_2_43_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_43_fast(v128 x,v128 y){return raw_model(x,y,2,43);}
extern v128 promoted_body_2_44_c(v128,v128);
extern uint64_t promoted_probe_2_44_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_44_c(v128 x,v128 y){return raw_model(x,y,2,44);}
extern v128 promoted_body_2_44_fast(v128,v128);
extern uint64_t promoted_probe_2_44_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_44_fast(v128 x,v128 y){return raw_model(x,y,2,44);}
extern v128 promoted_body_2_45_c(v128,v128);
extern uint64_t promoted_probe_2_45_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_45_c(v128 x,v128 y){return raw_model(x,y,2,45);}
extern v128 promoted_body_2_45_fast(v128,v128);
extern uint64_t promoted_probe_2_45_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_45_fast(v128 x,v128 y){return raw_model(x,y,2,45);}
extern v128 promoted_body_2_46_c(v128,v128);
extern uint64_t promoted_probe_2_46_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_46_c(v128 x,v128 y){return raw_model(x,y,2,46);}
extern v128 promoted_body_2_46_fast(v128,v128);
extern uint64_t promoted_probe_2_46_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_46_fast(v128 x,v128 y){return raw_model(x,y,2,46);}
extern v128 promoted_body_2_47_c(v128,v128);
extern uint64_t promoted_probe_2_47_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_47_c(v128 x,v128 y){return raw_model(x,y,2,47);}
extern v128 promoted_body_2_47_fast(v128,v128);
extern uint64_t promoted_probe_2_47_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_47_fast(v128 x,v128 y){return raw_model(x,y,2,47);}
extern v128 promoted_body_2_48_c(v128,v128);
extern uint64_t promoted_probe_2_48_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_48_c(v128 x,v128 y){return raw_model(x,y,2,48);}
extern v128 promoted_body_2_48_fast(v128,v128);
extern uint64_t promoted_probe_2_48_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_48_fast(v128 x,v128 y){return raw_model(x,y,2,48);}
extern v128 promoted_body_2_49_c(v128,v128);
extern uint64_t promoted_probe_2_49_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_49_c(v128 x,v128 y){return raw_model(x,y,2,49);}
extern v128 promoted_body_2_49_fast(v128,v128);
extern uint64_t promoted_probe_2_49_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_49_fast(v128 x,v128 y){return raw_model(x,y,2,49);}
extern v128 promoted_body_2_50_c(v128,v128);
extern uint64_t promoted_probe_2_50_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_50_c(v128 x,v128 y){return raw_model(x,y,2,50);}
extern v128 promoted_body_2_50_fast(v128,v128);
extern uint64_t promoted_probe_2_50_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_50_fast(v128 x,v128 y){return raw_model(x,y,2,50);}
extern v128 promoted_body_2_53_c(v128,v128);
extern uint64_t promoted_probe_2_53_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_53_c(v128 x,v128 y){return raw_model(x,y,2,53);}
extern v128 promoted_body_2_53_fast(v128,v128);
extern uint64_t promoted_probe_2_53_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_53_fast(v128 x,v128 y){return raw_model(x,y,2,53);}
extern v128 promoted_body_2_54_c(v128,v128);
extern uint64_t promoted_probe_2_54_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_54_c(v128 x,v128 y){return raw_model(x,y,2,54);}
extern v128 promoted_body_2_54_fast(v128,v128);
extern uint64_t promoted_probe_2_54_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_54_fast(v128 x,v128 y){return raw_model(x,y,2,54);}
extern v128 promoted_body_2_55_c(v128,v128);
extern uint64_t promoted_probe_2_55_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_55_c(v128 x,v128 y){return raw_model(x,y,2,55);}
extern v128 promoted_body_2_55_fast(v128,v128);
extern uint64_t promoted_probe_2_55_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_55_fast(v128 x,v128 y){return raw_model(x,y,2,55);}
extern v128 promoted_body_2_56_c(v128,v128);
extern uint64_t promoted_probe_2_56_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_56_c(v128 x,v128 y){return raw_model(x,y,2,56);}
extern v128 promoted_body_2_56_fast(v128,v128);
extern uint64_t promoted_probe_2_56_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_56_fast(v128 x,v128 y){return raw_model(x,y,2,56);}
extern v128 promoted_body_2_57_c(v128,v128);
extern uint64_t promoted_probe_2_57_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_57_c(v128 x,v128 y){return raw_model(x,y,2,57);}
extern v128 promoted_body_2_57_fast(v128,v128);
extern uint64_t promoted_probe_2_57_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_57_fast(v128 x,v128 y){return raw_model(x,y,2,57);}
extern v128 promoted_body_2_58_c(v128,v128);
extern uint64_t promoted_probe_2_58_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_58_c(v128 x,v128 y){return raw_model(x,y,2,58);}
extern v128 promoted_body_2_58_fast(v128,v128);
extern uint64_t promoted_probe_2_58_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_58_fast(v128 x,v128 y){return raw_model(x,y,2,58);}
extern v128 promoted_body_2_59_c(v128,v128);
extern uint64_t promoted_probe_2_59_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_59_c(v128 x,v128 y){return raw_model(x,y,2,59);}
extern v128 promoted_body_2_59_fast(v128,v128);
extern uint64_t promoted_probe_2_59_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_59_fast(v128 x,v128 y){return raw_model(x,y,2,59);}
extern v128 promoted_body_2_60_c(v128,v128);
extern uint64_t promoted_probe_2_60_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_60_c(v128 x,v128 y){return raw_model(x,y,2,60);}
extern v128 promoted_body_2_60_fast(v128,v128);
extern uint64_t promoted_probe_2_60_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_60_fast(v128 x,v128 y){return raw_model(x,y,2,60);}
extern v128 promoted_body_2_61_c(v128,v128);
extern uint64_t promoted_probe_2_61_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_61_c(v128 x,v128 y){return raw_model(x,y,2,61);}
extern v128 promoted_body_2_61_fast(v128,v128);
extern uint64_t promoted_probe_2_61_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_61_fast(v128 x,v128 y){return raw_model(x,y,2,61);}
extern v128 promoted_body_2_62_c(v128,v128);
extern uint64_t promoted_probe_2_62_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_62_c(v128 x,v128 y){return raw_model(x,y,2,62);}
extern v128 promoted_body_2_62_fast(v128,v128);
extern uint64_t promoted_probe_2_62_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_62_fast(v128 x,v128 y){return raw_model(x,y,2,62);}
extern v128 promoted_body_2_63_c(v128,v128);
extern uint64_t promoted_probe_2_63_c(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_63_c(v128 x,v128 y){return raw_model(x,y,2,63);}
extern v128 promoted_body_2_63_fast(v128,v128);
extern uint64_t promoted_probe_2_63_fast(void *,const void *,const void *,uint64_t);
v128 promoted_provider_2_63_fast(v128 x,v128 y){return raw_model(x,y,2,63);}
static const struct abi_case cases[]={
{2,1,promoted_probe_2_1_c,promoted_body_2_1_c},
{2,1,promoted_probe_2_1_fast,promoted_body_2_1_fast},
{2,2,promoted_probe_2_2_c,promoted_body_2_2_c},
{2,2,promoted_probe_2_2_fast,promoted_body_2_2_fast},
{2,3,promoted_probe_2_3_c,promoted_body_2_3_c},
{2,3,promoted_probe_2_3_fast,promoted_body_2_3_fast},
{2,4,promoted_probe_2_4_c,promoted_body_2_4_c},
{2,4,promoted_probe_2_4_fast,promoted_body_2_4_fast},
{2,5,promoted_probe_2_5_c,promoted_body_2_5_c},
{2,5,promoted_probe_2_5_fast,promoted_body_2_5_fast},
{2,6,promoted_probe_2_6_c,promoted_body_2_6_c},
{2,6,promoted_probe_2_6_fast,promoted_body_2_6_fast},
{2,7,promoted_probe_2_7_c,promoted_body_2_7_c},
{2,7,promoted_probe_2_7_fast,promoted_body_2_7_fast},
{2,9,promoted_probe_2_9_c,promoted_body_2_9_c},
{2,9,promoted_probe_2_9_fast,promoted_body_2_9_fast},
{2,10,promoted_probe_2_10_c,promoted_body_2_10_c},
{2,10,promoted_probe_2_10_fast,promoted_body_2_10_fast},
{2,11,promoted_probe_2_11_c,promoted_body_2_11_c},
{2,11,promoted_probe_2_11_fast,promoted_body_2_11_fast},
{2,12,promoted_probe_2_12_c,promoted_body_2_12_c},
{2,12,promoted_probe_2_12_fast,promoted_body_2_12_fast},
{2,13,promoted_probe_2_13_c,promoted_body_2_13_c},
{2,13,promoted_probe_2_13_fast,promoted_body_2_13_fast},
{2,14,promoted_probe_2_14_c,promoted_body_2_14_c},
{2,14,promoted_probe_2_14_fast,promoted_body_2_14_fast},
{2,15,promoted_probe_2_15_c,promoted_body_2_15_c},
{2,15,promoted_probe_2_15_fast,promoted_body_2_15_fast},
{2,17,promoted_probe_2_17_c,promoted_body_2_17_c},
{2,17,promoted_probe_2_17_fast,promoted_body_2_17_fast},
{2,18,promoted_probe_2_18_c,promoted_body_2_18_c},
{2,18,promoted_probe_2_18_fast,promoted_body_2_18_fast},
{2,19,promoted_probe_2_19_c,promoted_body_2_19_c},
{2,19,promoted_probe_2_19_fast,promoted_body_2_19_fast},
{2,20,promoted_probe_2_20_c,promoted_body_2_20_c},
{2,20,promoted_probe_2_20_fast,promoted_body_2_20_fast},
{2,21,promoted_probe_2_21_c,promoted_body_2_21_c},
{2,21,promoted_probe_2_21_fast,promoted_body_2_21_fast},
{2,22,promoted_probe_2_22_c,promoted_body_2_22_c},
{2,22,promoted_probe_2_22_fast,promoted_body_2_22_fast},
{2,23,promoted_probe_2_23_c,promoted_body_2_23_c},
{2,23,promoted_probe_2_23_fast,promoted_body_2_23_fast},
{2,24,promoted_probe_2_24_c,promoted_body_2_24_c},
{2,24,promoted_probe_2_24_fast,promoted_body_2_24_fast},
{2,25,promoted_probe_2_25_c,promoted_body_2_25_c},
{2,25,promoted_probe_2_25_fast,promoted_body_2_25_fast},
{2,26,promoted_probe_2_26_c,promoted_body_2_26_c},
{2,26,promoted_probe_2_26_fast,promoted_body_2_26_fast},
{2,27,promoted_probe_2_27_c,promoted_body_2_27_c},
{2,27,promoted_probe_2_27_fast,promoted_body_2_27_fast},
{2,28,promoted_probe_2_28_c,promoted_body_2_28_c},
{2,28,promoted_probe_2_28_fast,promoted_body_2_28_fast},
{2,29,promoted_probe_2_29_c,promoted_body_2_29_c},
{2,29,promoted_probe_2_29_fast,promoted_body_2_29_fast},
{2,30,promoted_probe_2_30_c,promoted_body_2_30_c},
{2,30,promoted_probe_2_30_fast,promoted_body_2_30_fast},
{2,31,promoted_probe_2_31_c,promoted_body_2_31_c},
{2,31,promoted_probe_2_31_fast,promoted_body_2_31_fast},
{2,33,promoted_probe_2_33_c,promoted_body_2_33_c},
{2,33,promoted_probe_2_33_fast,promoted_body_2_33_fast},
{2,34,promoted_probe_2_34_c,promoted_body_2_34_c},
{2,34,promoted_probe_2_34_fast,promoted_body_2_34_fast},
{2,35,promoted_probe_2_35_c,promoted_body_2_35_c},
{2,35,promoted_probe_2_35_fast,promoted_body_2_35_fast},
{2,36,promoted_probe_2_36_c,promoted_body_2_36_c},
{2,36,promoted_probe_2_36_fast,promoted_body_2_36_fast},
{2,37,promoted_probe_2_37_c,promoted_body_2_37_c},
{2,37,promoted_probe_2_37_fast,promoted_body_2_37_fast},
{2,38,promoted_probe_2_38_c,promoted_body_2_38_c},
{2,38,promoted_probe_2_38_fast,promoted_body_2_38_fast},
{2,39,promoted_probe_2_39_c,promoted_body_2_39_c},
{2,39,promoted_probe_2_39_fast,promoted_body_2_39_fast},
{2,40,promoted_probe_2_40_c,promoted_body_2_40_c},
{2,40,promoted_probe_2_40_fast,promoted_body_2_40_fast},
{2,41,promoted_probe_2_41_c,promoted_body_2_41_c},
{2,41,promoted_probe_2_41_fast,promoted_body_2_41_fast},
{2,42,promoted_probe_2_42_c,promoted_body_2_42_c},
{2,42,promoted_probe_2_42_fast,promoted_body_2_42_fast},
{2,43,promoted_probe_2_43_c,promoted_body_2_43_c},
{2,43,promoted_probe_2_43_fast,promoted_body_2_43_fast},
{2,44,promoted_probe_2_44_c,promoted_body_2_44_c},
{2,44,promoted_probe_2_44_fast,promoted_body_2_44_fast},
{2,45,promoted_probe_2_45_c,promoted_body_2_45_c},
{2,45,promoted_probe_2_45_fast,promoted_body_2_45_fast},
{2,46,promoted_probe_2_46_c,promoted_body_2_46_c},
{2,46,promoted_probe_2_46_fast,promoted_body_2_46_fast},
{2,47,promoted_probe_2_47_c,promoted_body_2_47_c},
{2,47,promoted_probe_2_47_fast,promoted_body_2_47_fast},
{2,48,promoted_probe_2_48_c,promoted_body_2_48_c},
{2,48,promoted_probe_2_48_fast,promoted_body_2_48_fast},
{2,49,promoted_probe_2_49_c,promoted_body_2_49_c},
{2,49,promoted_probe_2_49_fast,promoted_body_2_49_fast},
{2,50,promoted_probe_2_50_c,promoted_body_2_50_c},
{2,50,promoted_probe_2_50_fast,promoted_body_2_50_fast},
{2,53,promoted_probe_2_53_c,promoted_body_2_53_c},
{2,53,promoted_probe_2_53_fast,promoted_body_2_53_fast},
{2,54,promoted_probe_2_54_c,promoted_body_2_54_c},
{2,54,promoted_probe_2_54_fast,promoted_body_2_54_fast},
{2,55,promoted_probe_2_55_c,promoted_body_2_55_c},
{2,55,promoted_probe_2_55_fast,promoted_body_2_55_fast},
{2,56,promoted_probe_2_56_c,promoted_body_2_56_c},
{2,56,promoted_probe_2_56_fast,promoted_body_2_56_fast},
{2,57,promoted_probe_2_57_c,promoted_body_2_57_c},
{2,57,promoted_probe_2_57_fast,promoted_body_2_57_fast},
{2,58,promoted_probe_2_58_c,promoted_body_2_58_c},
{2,58,promoted_probe_2_58_fast,promoted_body_2_58_fast},
{2,59,promoted_probe_2_59_c,promoted_body_2_59_c},
{2,59,promoted_probe_2_59_fast,promoted_body_2_59_fast},
{2,60,promoted_probe_2_60_c,promoted_body_2_60_c},
{2,60,promoted_probe_2_60_fast,promoted_body_2_60_fast},
{2,61,promoted_probe_2_61_c,promoted_body_2_61_c},
{2,61,promoted_probe_2_61_fast,promoted_body_2_61_fast},
{2,62,promoted_probe_2_62_c,promoted_body_2_62_c},
{2,62,promoted_probe_2_62_fast,promoted_body_2_62_fast},
{2,63,promoted_probe_2_63_c,promoted_body_2_63_c},
{2,63,promoted_probe_2_63_fast,promoted_body_2_63_fast},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
