#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef uint64_t (*probe_fn)(void *,void *,uint64_t,uint64_t);
union body_fn{_Float16 (*h)(uint32_t,uint64_t,void *);float (*f)(uint32_t,uint64_t,void *);double (*d)(uint32_t,uint64_t,void *);};
struct test_case{unsigned bits,index;union body_fn body;probe_fn probe;};
struct effect{unsigned char pre[9],data[8],post[9];};
static uint64_t payload(unsigned bits,unsigned index){
 static const uint64_t h[]={0,0x8000,1,0x7c00,0x7c01,0x7e23,0x3555};
 static const uint64_t f[]={0,0x80000000,1,0x7f800000,0x7f800001,0x7fc00123,0x3eaaaaab};
 static const uint64_t d[]={0,UINT64_C(0x8000000000000000),1,UINT64_C(0x7ff0000000000000),UINT64_C(0x7ff0000000000001),UINT64_C(0x7ff8000000000123),UINT64_C(0x3fd5555555555555)};
 return (bits==16?h:bits==32?f:d)[index];
}
static int effect_equal(const struct effect *effect,uint64_t salt){int pass=memcmp(effect->data,&salt,8)==0;for(unsigned i=0;i<9;i++)pass&=effect->pre[i]==0xa5&&effect->post[i]==0xa5;return pass;}
static size_t observations;
static void check(int pass,unsigned slot,unsigned seed,unsigned fault){observations++;if(!pass){fprintf(stderr,"native-fp-literals slot=%u seed=%u observation=%zu fault=%u\n",slot,seed,observations,fault);exit(1);}}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;
 for(unsigned slot=0;slot<count;slot++)for(unsigned seed=0;seed<64;seed++){
  unsigned bytes=cases[slot].bits/8,choice=seed&1;uint64_t salt=(seed+slot*37)*UINT64_C(0xf06dea67e461de5b),expected=payload(cases[slot].bits,choice?cases[slot].index:1),actual=0;
  struct effect direct_effect;memset(&direct_effect,0xa5,sizeof direct_effect);
  switch(cases[slot].bits){case 16:{_Float16 v=cases[slot].body.h(choice,salt,direct_effect.data);memcpy(&actual,&v,2);break;}case 32:{float v=cases[slot].body.f(choice,salt,direct_effect.data);memcpy(&actual,&v,4);break;}case 64:{double v=cases[slot].body.d(choice,salt,direct_effect.data);memcpy(&actual,&v,8);break;}default:return 2;}
  check(actual==expected,slot,seed,fault);check(effect_equal(&direct_effect,salt),slot,seed,fault);
  struct{unsigned char pre[9],data[32],post[9];}out;struct effect local_effect;memset(&out,0xa5,sizeof out);memset(&local_effect,0xa5,sizeof local_effect);
  uint64_t returned=cases[slot].probe(out.data,local_effect.data,seed,salt);if(fault==1)returned^=1;if(fault==2)out.data[0]^=1;if(fault==3)out.post[0]^=1;
  check(returned==(salt^90),slot,seed,fault);check(memcmp(out.data,&expected,bytes)==0,slot,seed,fault);check(memcmp(out.data+16,&expected,bytes)==0,slot,seed,fault);check(effect_equal(&local_effect,salt),slot,seed,fault);
  int pre=1,post=1,gap0=1,gap1=1;for(unsigned i=0;i<9;i++){pre&=out.pre[i]==0xa5;post&=out.post[i]==0xa5;}for(unsigned i=bytes;i<16;i++){gap0&=out.data[i]==0xa5;gap1&=out.data[i+16]==0xa5;}
  check(pre,slot,seed,fault);check(post,slot,seed,fault);check(gap0,slot,seed,fault);check(gap1,slot,seed,fault);
 }
 if(count!=42||observations!=26880)return 2;printf("native-fp-literals observations=%zu exact-payloads=ccc-fastcc=llvm-c-local-interop=volatile-effects=guards=preserved\n",observations);return 0;
}
