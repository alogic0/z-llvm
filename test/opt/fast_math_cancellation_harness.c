#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern double fast_cancel64(double),fast_commute64(double),fast_sub_add64(double);
extern double fast_shared64(double,double *),strict_cancel64(double),strict_inner64(double),partial_outer64(double);
extern float fast_cancel32(float),strict_cancel32(float);
static uint64_t bits64(double x) { uint64_t bits;memcpy(&bits,&x,8);return bits; }
static uint32_t bits32(float x) { uint32_t bits;memcpy(&bits,&x,4);return bits; }
static int check(uint64_t actual,uint64_t expected,unsigned kind,unsigned input,unsigned fault) {
 if(actual==expected) return 0;
 fprintf(stderr,"fastmath-cancellation kind=%u input=%u fault=%u actual=%016llx expected=%016llx\n",kind,input,fault,(unsigned long long)actual,(unsigned long long)expected);
 return 1;
}
int main(int argc,char **argv) {
 unsigned fault=argc==2?(unsigned)strtoul(argv[1],0,10):0;
 if(argc>2||fault>4) return 2;
 static const uint64_t edge64[]={0,1,UINT64_C(0x8000000000000000),UINT64_C(0x8000000000000001),
  UINT64_C(0x0010000000000000),UINT64_C(0x8010000000000000),UINT64_C(0x3f50000000000000),UINT64_C(0x3f50624dd2f1a9fc),
  UINT64_C(0xbf50624dd2f1a9fc),UINT64_C(0x4270000000000000),UINT64_C(0xc270000000000000),UINT64_C(0x3ff0000000000000),
  UINT64_C(0xbff0000000000000),UINT64_C(0x7fefffffffffffff),UINT64_C(0xffefffffffffffff),UINT64_C(0x001fffffffffffff)};
 static const uint32_t edge32[]={0,1,UINT32_C(0x80000000),UINT32_C(0x80000001),UINT32_C(0x00800000),UINT32_C(0x80800000),
  UINT32_C(0x3a800000),UINT32_C(0x3a83126f),UINT32_C(0xba83126f),UINT32_C(0x4b800000),UINT32_C(0xcb800000),
  UINT32_C(0x3f800000),UINT32_C(0xbf800000),UINT32_C(0x7f7fffff),UINT32_C(0xff7fffff),UINT32_C(0x00ffffff)};
 unsigned observations=0;
 uint64_t state=UINT64_C(0x5eed12349e3779b9);
 for(unsigned i=0;i<512;++i) {
  state^=state<<13;state^=state>>7;state^=state<<17;
  uint64_t raw64=i<16?edge64[i]:state;
  if((raw64&UINT64_C(0x7ff0000000000000))==UINT64_C(0x7ff0000000000000)) raw64^=UINT64_C(1)<<52;
  uint32_t raw32=i<16?edge32[i]:(uint32_t)(state^(state>>32));
  if((raw32&UINT32_C(0x7f800000))==UINT32_C(0x7f800000)) raw32^=UINT32_C(1)<<23;
  double x;float y;memcpy(&x,&raw64,8);memcpy(&y,&raw32,4);
  volatile double sum=x+0x1p40;volatile double rounded=sum-0x1p40;
  volatile float sum32=y+0x1p24f;volatile float rounded32=sum32-0x1p24f;
  uint64_t value=bits64(fast_cancel64(x));if(fault==1) value^=1;
  if(check(value,raw64,0,i,fault)) return 1;++observations;
  if(check(bits64(fast_commute64(x)),raw64,1,i,fault)) return 1;++observations;
  if(check(bits64(fast_sub_add64(x)),raw64,2,i,fault)) return 1;++observations;
  double snapshot=0;
  if(check(bits64(fast_shared64(x,&snapshot)),raw64,3,i,fault)) return 1;++observations;
  value=bits64(snapshot);if(fault==3) value^=1;
  if(check(value,bits64(sum),4,i,fault)) return 1;++observations;
  value=bits64(strict_cancel64(x));if(fault==2) value^=1;
  if(check(value,bits64(rounded),5,i,fault)) return 1;++observations;
  if(check(bits64(strict_inner64(x)),bits64(rounded),6,i,fault)) return 1;++observations;
  if(check(bits64(partial_outer64(x)),bits64(rounded),7,i,fault)) return 1;++observations;
  value=bits32(fast_cancel32(y));if(fault==4) value^=1;
  if(check(value,raw32,8,i,fault)) return 1;++observations;
  if(check(bits32(strict_cancel32(y)),bits32(rounded32),9,i,fault)) return 1;++observations;
 }
 if(observations!=5120) return 2;
 printf("fastmath-cancellation functions=9 observations=%u independent-c-bit-goldens=finite-payloads=strict-rounding=partial-flags=shared-values=preserved\n",observations);
 return 0;
}
