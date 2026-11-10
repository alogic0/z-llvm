#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
extern unsigned char symbolic_word_data[64];
typedef uint64_t (*word_fn)(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
#define DECLARE(name) extern uint64_t name(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t)
DECLARE(symbolic_word_lhs);DECLARE(symbolic_word_rhs);DECLARE(symbolic_word_offset);
DECLARE(symbolic_word_quoted);DECLARE(symbolic_word_both);DECLARE(symbolic_word_pressure);
static const word_fn functions[]={symbolic_word_lhs,symbolic_word_rhs,symbolic_word_offset,symbolic_word_quoted,symbolic_word_both,symbolic_word_pressure};
static unsigned observations,fault;
static int mismatch(const char *kind,unsigned function,unsigned value,unsigned seed) {
 fprintf(stderr,"integer symbolic mismatch kind=%s function=%u value=%u seed=%u fault=%u observation=%u\n",kind,function,value,seed,fault,observations);return 1;
}
int main(int argc,char **argv) {
 if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;
 const uint64_t base=(uintptr_t)symbolic_word_data;
 const uint64_t values[]={0,1,7,63,UINT64_MAX,UINT64_C(0x8000000000000000),UINT64_C(0x7fffffffffffffff),UINT64_C(0x0123456789abcdef),UINT64_C(0xfedcba9876543210),base,base-1,base+1,base+9,base+63,base-8,base^UINT64_C(0x8000000000000000)};
 const uint64_t seeds[]={0,1,UINT64_C(0x55aa55aa12345678),UINT64_MAX};
 for(unsigned k=0;k<6;k++)for(unsigned i=0;i<16;i++)for(unsigned j=0;j<4;j++) {
  const uint64_t seed=seeds[j],a=values[i],b=values[(i+3)&15]^seed,c=values[(i+5)&15]+seed,d=values[(i+9)&15]^(seed<<1),e=values[(i+11)&15]-seed;
  uint64_t expected;
  switch(k) {
   case 0:expected=(base-a)^seed;break;
   case 1:expected=(a-base)^seed;break;
   case 2:expected=(base+17-a)^seed;break;
   case 3:expected=(base+9-a)^seed;break;
   case 4:expected=UINT64_C(17)^a^seed;break;
   default:expected=(((((base-a)^b)+c)^d)-e)^seed;break;
  }
  uint64_t actual=functions[k](a,b,c,d,e,seed);
  if(fault==1)actual^=1;if(fault==2)symbolic_word_data[0]^=1;if(fault==3)symbolic_word_data[63]^=1;
  if(actual!=expected)return mismatch("result",k,i,j);
  for(unsigned byte=0;byte<64;byte++)if(symbolic_word_data[byte])return mismatch("memory",k,i,j);
  observations++;
 }
 if(observations!=384)return mismatch("count",0,0,0);
 puts("integer-symbolic-operands observations=384 lhs=rhs=offsets=quoted=pressure=preserved");return 0;
}
