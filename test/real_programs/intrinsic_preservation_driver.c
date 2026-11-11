#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef uint64_t (*oracle_fn)(uint64_t,const void *,void *,uint64_t);
struct oracle_case { oracle_fn run; unsigned operation,bits,shape; };
extern uint64_t intrinsic_preservation_count64_register(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_count64_computed(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_count64_load(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_leading16_register(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_leading16_computed(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_leading16_load(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_swap16_register(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_swap16_computed(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_swap16_load(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_swap32_register(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_swap32_computed(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_swap32_load(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_swap64_register(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_swap64_computed(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_swap64_load(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_reverse32_register(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_reverse32_computed(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_reverse32_load(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_reverse64_register(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_reverse64_computed(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_reverse64_load(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_funnel32_register(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_funnel32_computed(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_funnel32_load(uint64_t,const void *,void *,uint64_t);
extern uint64_t intrinsic_preservation_roundup(uint16_t);
static const struct oracle_case cases[]={
 {intrinsic_preservation_count64_register,0,64,0},
 {intrinsic_preservation_count64_computed,0,64,1},
 {intrinsic_preservation_count64_load,0,64,2},
 {intrinsic_preservation_leading16_register,1,16,0},
 {intrinsic_preservation_leading16_computed,1,16,1},
 {intrinsic_preservation_leading16_load,1,16,2},
 {intrinsic_preservation_swap16_register,2,16,0},
 {intrinsic_preservation_swap16_computed,2,16,1},
 {intrinsic_preservation_swap16_load,2,16,2},
 {intrinsic_preservation_swap32_register,3,32,0},
 {intrinsic_preservation_swap32_computed,3,32,1},
 {intrinsic_preservation_swap32_load,3,32,2},
 {intrinsic_preservation_swap64_register,4,64,0},
 {intrinsic_preservation_swap64_computed,4,64,1},
 {intrinsic_preservation_swap64_load,4,64,2},
 {intrinsic_preservation_reverse32_register,5,32,0},
 {intrinsic_preservation_reverse32_computed,5,32,1},
 {intrinsic_preservation_reverse32_load,5,32,2},
 {intrinsic_preservation_reverse64_register,6,64,0},
 {intrinsic_preservation_reverse64_computed,6,64,1},
 {intrinsic_preservation_reverse64_load,6,64,2},
 {intrinsic_preservation_funnel32_register,7,32,0},
 {intrinsic_preservation_funnel32_computed,7,32,1},
 {intrinsic_preservation_funnel32_load,7,32,2},
};
static unsigned population(uint64_t value,unsigned bits) {
 unsigned count=0;
 for(unsigned bit=0;bit<bits;bit++) count+=(unsigned)((value>>bit)&1);
 return count;
}
static uint64_t expected(unsigned operation,uint64_t value,unsigned bits) {
 uint64_t result=0;
 if(operation==0) return population(value,bits);
 if(operation==1) {
  unsigned count=0;
  for(unsigned bit=bits;bit>0;bit--) { if((value>>(bit-1))&1) break; count++; }
  return count;
 }
 if(operation>=2 && operation<=4) {
  for(unsigned byte=0;byte<bits/8;byte++) result|=((value>>(byte*8))&255)<<(bits-8-byte*8);
  return result;
 }
 if(operation==5 || operation==6) {
  for(unsigned bit=0;bit<bits;bit++) result|=((value>>bit)&1)<<(bits-1-bit);
  return result;
 }
 return (uint32_t)(((uint32_t)value<<7)|((uint32_t)value>>25));
}
int main(int argc,char **argv) {
 const unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;
 unsigned observations=0;
#define CHECK(condition) do { ++observations; if(!(condition)) { fprintf(stderr,"intrinsic-preservation observation=%u fault=%u\n",observations,fault); return 1; } } while(0)
 const uint64_t values[]={0,1,2,3,4,7,8,15,16,31,32,63,64,80,UINT64_C(0x8000000000000000),UINT64_MAX};
 for(unsigned n=0;n<sizeof(values)/sizeof(values[0]);n++) {
  const uint64_t raw=values[n],salt=raw^UINT64_C(0x97c63e5ab40d128f);
  for(unsigned k=0;k<sizeof(cases)/sizeof(cases[0]);k++) {
   const struct oracle_case *test=&cases[k];
   const unsigned width=test->bits/8;
   const uint64_t mask=test->bits==64?UINT64_MAX:((UINT64_C(1)<<test->bits)-1);
   uint64_t value=raw&mask;
   if(test->shape==1) value^=UINT64_C(0x5aa5);
   unsigned char source[32],before[32],out[32],wanted[32];
   memset(source,0xc3,sizeof(source)); memcpy(source+5,&raw,8); memcpy(before,source,sizeof(source));
   memset(out,0xa5,sizeof(out)); memset(wanted,0xa5,sizeof(wanted));
   memcpy(wanted+8,&value,width); memcpy(wanted+16,&value,width);
   uint64_t answer=test->run(raw,source+5,out+8,salt);
   CHECK((answer^(fault==1))==(expected(test->operation,value,test->bits)^value^salt));
   if(fault==2) out[0]^=1;
   CHECK(memcmp(out,wanted,sizeof(out))==0);
   CHECK(memcmp(source,before,sizeof(source))==0);
  }
  const uint64_t value=(uint16_t)raw;
  const uint64_t rounded=((value+9)&(UINT64_C(0)-value))+population(value,64);
  CHECK((intrinsic_preservation_roundup((uint16_t)raw)^(fault==3))==rounded);
 }
 if(observations!=1168) { fprintf(stderr,"wrong observation count=%u\n",observations); return 2; }
 puts("intrinsic-preservation observations=1168 live=aliases=memory=preserved");
 return 0;
}
