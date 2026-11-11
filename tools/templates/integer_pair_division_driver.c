#include <stdio.h>
#include <stdlib.h>
static unsigned observations,fault;
static wide quotient_remainder(wide numerator,wide denominator,wide *remainder){
 wide q=0,r=0;
 for(unsigned bit=128;bit-->0;){
  unsigned carry=(unsigned)(r>>127);r=(r<<1)|((numerator>>bit)&1);
  if(carry||r>=denominator){r-=denominator;q|=(wide)1<<bit;}
 }
 *remainder=r;return q;
}
static wide oracle(unsigned op,wide numerator,wide denominator){
 unsigned negative_numerator=0,negative_denominator=0;
 if(op>=2){negative_numerator=(unsigned)(numerator>>127);negative_denominator=(unsigned)(denominator>>127);}
 wide a=negative_numerator?-numerator:numerator,b=negative_denominator?-denominator:denominator,r;
 wide q=quotient_remainder(a,b,&r);
 if(negative_numerator!=negative_denominator)q=-q;
 if(negative_numerator)r=-r;
 return (op&1)?r:q;
}
static int mismatch(unsigned which,unsigned a,unsigned b,unsigned seed,wide expected,wide actual){
 fprintf(stderr,"pair division mismatch case=%u a=%u b=%u seed=%u fault=%u observation=%u expected=%016llx:%016llx actual=%016llx:%016llx\n",which,a,b,seed,fault,observations,(unsigned long long)(expected>>64),(unsigned long long)expected,(unsigned long long)(actual>>64),(unsigned long long)actual);return 1;
}
int main(int argc,char **argv){
 if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;
 const wide top=(wide)1<<127,large=((wide)1<<96)+3;
 const wide values[]={0,1,2,3,7,17,UINT32_MAX,(wide)1<<32,UINT64_MAX,(wide)1<<64,((wide)1<<64)+1,large,top-1,top,~(wide)1,~(wide)0};
 const uint64_t seeds[]={0,1,UINT64_C(0xa55a55aa12345678),UINT64_MAX};
 for(unsigned k=0;k<sizeof(cases)/sizeof(cases[0]);k++)for(unsigned a=0;a<16;a++)for(unsigned b=0;b<16;b++)for(unsigned s=0;s<4;s++){
  wide denominator=cases[k].constant?(cases[k].op<2?large:-large):values[b];
  if(!denominator||(cases[k].op>=2&&values[a]==top&&denominator==~(wide)0))continue;
  uint64_t seed=seeds[s],live1=(uint64_t)values[a]^seed,live2=(uint64_t)(values[b]>>64)+seed,live3=(uint64_t)(values[a]>>64)^(uint64_t)values[b];
  wide expected=oracle(cases[k].op,values[a],denominator)^values[a]^values[b]^(wide)(((seed^live1)+live2)^live3);
  wide actual=cases[k].run(values[a],values[b],seed,live1,live2,live3);
  if(fault==1)actual^=1;if(fault==2)actual^=(wide)1<<127;if(fault==3)actual^=(wide)1<<64;
  if(actual!=expected)return mismatch(k,a,b,s,expected,actual);observations++;
 }
 if(observations!=7928)return mismatch(0,0,0,0,7928,observations);
 puts("integer-pair-division observations=7928 quotient=remainder=signed=live=abi=preserved");return 0;
}
