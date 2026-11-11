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
