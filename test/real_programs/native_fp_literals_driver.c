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
extern _Float16 fp_literal_body_16_0_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_0_c(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_0_c(uint32_t choice){uint64_t bits=payload(16,(choice&1)?0:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_0_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_0_fast(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_0_fast(uint32_t choice){uint64_t bits=payload(16,(choice&1)?0:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_1_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_1_c(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_1_c(uint32_t choice){uint64_t bits=payload(16,(choice&1)?1:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_1_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_1_fast(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_1_fast(uint32_t choice){uint64_t bits=payload(16,(choice&1)?1:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_2_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_2_c(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_2_c(uint32_t choice){uint64_t bits=payload(16,(choice&1)?2:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_2_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_2_fast(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_2_fast(uint32_t choice){uint64_t bits=payload(16,(choice&1)?2:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_3_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_3_c(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_3_c(uint32_t choice){uint64_t bits=payload(16,(choice&1)?3:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_3_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_3_fast(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_3_fast(uint32_t choice){uint64_t bits=payload(16,(choice&1)?3:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_4_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_4_c(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_4_c(uint32_t choice){uint64_t bits=payload(16,(choice&1)?4:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_4_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_4_fast(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_4_fast(uint32_t choice){uint64_t bits=payload(16,(choice&1)?4:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_5_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_5_c(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_5_c(uint32_t choice){uint64_t bits=payload(16,(choice&1)?5:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_5_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_5_fast(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_5_fast(uint32_t choice){uint64_t bits=payload(16,(choice&1)?5:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_6_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_6_c(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_6_c(uint32_t choice){uint64_t bits=payload(16,(choice&1)?6:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern _Float16 fp_literal_body_16_6_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_16_6_fast(void *,void *,uint64_t,uint64_t);
_Float16 fp_literal_provider_16_6_fast(uint32_t choice){uint64_t bits=payload(16,(choice&1)?6:1);_Float16 result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_0_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_0_c(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_0_c(uint32_t choice){uint64_t bits=payload(32,(choice&1)?0:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_0_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_0_fast(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_0_fast(uint32_t choice){uint64_t bits=payload(32,(choice&1)?0:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_1_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_1_c(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_1_c(uint32_t choice){uint64_t bits=payload(32,(choice&1)?1:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_1_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_1_fast(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_1_fast(uint32_t choice){uint64_t bits=payload(32,(choice&1)?1:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_2_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_2_c(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_2_c(uint32_t choice){uint64_t bits=payload(32,(choice&1)?2:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_2_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_2_fast(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_2_fast(uint32_t choice){uint64_t bits=payload(32,(choice&1)?2:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_3_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_3_c(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_3_c(uint32_t choice){uint64_t bits=payload(32,(choice&1)?3:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_3_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_3_fast(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_3_fast(uint32_t choice){uint64_t bits=payload(32,(choice&1)?3:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_4_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_4_c(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_4_c(uint32_t choice){uint64_t bits=payload(32,(choice&1)?4:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_4_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_4_fast(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_4_fast(uint32_t choice){uint64_t bits=payload(32,(choice&1)?4:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_5_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_5_c(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_5_c(uint32_t choice){uint64_t bits=payload(32,(choice&1)?5:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_5_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_5_fast(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_5_fast(uint32_t choice){uint64_t bits=payload(32,(choice&1)?5:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_6_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_6_c(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_6_c(uint32_t choice){uint64_t bits=payload(32,(choice&1)?6:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern float fp_literal_body_32_6_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_32_6_fast(void *,void *,uint64_t,uint64_t);
float fp_literal_provider_32_6_fast(uint32_t choice){uint64_t bits=payload(32,(choice&1)?6:1);float result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_0_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_0_c(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_0_c(uint32_t choice){uint64_t bits=payload(64,(choice&1)?0:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_0_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_0_fast(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_0_fast(uint32_t choice){uint64_t bits=payload(64,(choice&1)?0:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_1_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_1_c(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_1_c(uint32_t choice){uint64_t bits=payload(64,(choice&1)?1:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_1_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_1_fast(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_1_fast(uint32_t choice){uint64_t bits=payload(64,(choice&1)?1:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_2_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_2_c(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_2_c(uint32_t choice){uint64_t bits=payload(64,(choice&1)?2:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_2_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_2_fast(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_2_fast(uint32_t choice){uint64_t bits=payload(64,(choice&1)?2:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_3_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_3_c(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_3_c(uint32_t choice){uint64_t bits=payload(64,(choice&1)?3:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_3_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_3_fast(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_3_fast(uint32_t choice){uint64_t bits=payload(64,(choice&1)?3:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_4_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_4_c(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_4_c(uint32_t choice){uint64_t bits=payload(64,(choice&1)?4:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_4_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_4_fast(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_4_fast(uint32_t choice){uint64_t bits=payload(64,(choice&1)?4:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_5_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_5_c(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_5_c(uint32_t choice){uint64_t bits=payload(64,(choice&1)?5:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_5_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_5_fast(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_5_fast(uint32_t choice){uint64_t bits=payload(64,(choice&1)?5:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_6_c(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_6_c(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_6_c(uint32_t choice){uint64_t bits=payload(64,(choice&1)?6:1);double result;memcpy(&result,&bits,sizeof result);return result;}
extern double fp_literal_body_64_6_fast(uint32_t,uint64_t,void *);
extern uint64_t fp_literal_probe_64_6_fast(void *,void *,uint64_t,uint64_t);
double fp_literal_provider_64_6_fast(uint32_t choice){uint64_t bits=payload(64,(choice&1)?6:1);double result;memcpy(&result,&bits,sizeof result);return result;}
static const struct test_case cases[]={
{16,0,{.h=fp_literal_body_16_0_c},fp_literal_probe_16_0_c},
{16,0,{.h=fp_literal_body_16_0_fast},fp_literal_probe_16_0_fast},
{16,1,{.h=fp_literal_body_16_1_c},fp_literal_probe_16_1_c},
{16,1,{.h=fp_literal_body_16_1_fast},fp_literal_probe_16_1_fast},
{16,2,{.h=fp_literal_body_16_2_c},fp_literal_probe_16_2_c},
{16,2,{.h=fp_literal_body_16_2_fast},fp_literal_probe_16_2_fast},
{16,3,{.h=fp_literal_body_16_3_c},fp_literal_probe_16_3_c},
{16,3,{.h=fp_literal_body_16_3_fast},fp_literal_probe_16_3_fast},
{16,4,{.h=fp_literal_body_16_4_c},fp_literal_probe_16_4_c},
{16,4,{.h=fp_literal_body_16_4_fast},fp_literal_probe_16_4_fast},
{16,5,{.h=fp_literal_body_16_5_c},fp_literal_probe_16_5_c},
{16,5,{.h=fp_literal_body_16_5_fast},fp_literal_probe_16_5_fast},
{16,6,{.h=fp_literal_body_16_6_c},fp_literal_probe_16_6_c},
{16,6,{.h=fp_literal_body_16_6_fast},fp_literal_probe_16_6_fast},
{32,0,{.f=fp_literal_body_32_0_c},fp_literal_probe_32_0_c},
{32,0,{.f=fp_literal_body_32_0_fast},fp_literal_probe_32_0_fast},
{32,1,{.f=fp_literal_body_32_1_c},fp_literal_probe_32_1_c},
{32,1,{.f=fp_literal_body_32_1_fast},fp_literal_probe_32_1_fast},
{32,2,{.f=fp_literal_body_32_2_c},fp_literal_probe_32_2_c},
{32,2,{.f=fp_literal_body_32_2_fast},fp_literal_probe_32_2_fast},
{32,3,{.f=fp_literal_body_32_3_c},fp_literal_probe_32_3_c},
{32,3,{.f=fp_literal_body_32_3_fast},fp_literal_probe_32_3_fast},
{32,4,{.f=fp_literal_body_32_4_c},fp_literal_probe_32_4_c},
{32,4,{.f=fp_literal_body_32_4_fast},fp_literal_probe_32_4_fast},
{32,5,{.f=fp_literal_body_32_5_c},fp_literal_probe_32_5_c},
{32,5,{.f=fp_literal_body_32_5_fast},fp_literal_probe_32_5_fast},
{32,6,{.f=fp_literal_body_32_6_c},fp_literal_probe_32_6_c},
{32,6,{.f=fp_literal_body_32_6_fast},fp_literal_probe_32_6_fast},
{64,0,{.d=fp_literal_body_64_0_c},fp_literal_probe_64_0_c},
{64,0,{.d=fp_literal_body_64_0_fast},fp_literal_probe_64_0_fast},
{64,1,{.d=fp_literal_body_64_1_c},fp_literal_probe_64_1_c},
{64,1,{.d=fp_literal_body_64_1_fast},fp_literal_probe_64_1_fast},
{64,2,{.d=fp_literal_body_64_2_c},fp_literal_probe_64_2_c},
{64,2,{.d=fp_literal_body_64_2_fast},fp_literal_probe_64_2_fast},
{64,3,{.d=fp_literal_body_64_3_c},fp_literal_probe_64_3_c},
{64,3,{.d=fp_literal_body_64_3_fast},fp_literal_probe_64_3_fast},
{64,4,{.d=fp_literal_body_64_4_c},fp_literal_probe_64_4_c},
{64,4,{.d=fp_literal_body_64_4_fast},fp_literal_probe_64_4_fast},
{64,5,{.d=fp_literal_body_64_5_c},fp_literal_probe_64_5_c},
{64,5,{.d=fp_literal_body_64_5_fast},fp_literal_probe_64_5_fast},
{64,6,{.d=fp_literal_body_64_6_c},fp_literal_probe_64_6_c},
{64,6,{.d=fp_literal_body_64_6_fast},fp_literal_probe_64_6_fast},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
