#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef unsigned __int128 u128;
extern uint32_t values_bswap32(uint32_t);
extern uint64_t values_bswap64(uint64_t);
extern float values_copysign32(float,float);
extern double values_copysign64(double,double);
extern u128 values_zero_return(u128,_Bool);
extern u128 values_wide_literal(void);
extern uint64_t values_signed3(uint8_t);
extern uint64_t values_unsigned3(uint8_t);
extern uint64_t values_srem32_call(uint32_t,uint64_t);
extern uint32_t values_srem32_plain(uint32_t);
__attribute__((noinline)) uint32_t values_int_source(uint32_t input) {
 __asm__ volatile("movabs $0x1122334455667788,%%rcx\n\t"
                  "movabs $0x2233445566778899,%%rdx\n\t"
                  "movabs $0x33445566778899aa,%%rsi\n\t"
                  "movabs $0x445566778899aabb,%%r8\n\t"
                  "movabs $0x5566778899aabbcc,%%r9\n\t"
                  "pxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1"
                  ::: "rcx","rdx","rsi","r8","r9","xmm0","xmm1","cc","memory");
 return input;
}
static uint64_t swap(uint64_t x,unsigned bytes) {
 uint64_t out=0;
 for(unsigned n=0;n<bytes;++n) { out=(out<<8)|(x&255); x>>=8; }
 return out;
}
static const uint64_t payloads[]={0,1,0x7ff,0x80000000,0xffffffff,
 UINT64_C(0x8000000000000000),UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000),
 UINT64_C(0x7ff123456789abcd),UINT64_C(0xfff8abcd01234567),UINT64_MAX,
 UINT64_C(0x3ff0000000000000),UINT64_C(0x0010000000000000),UINT64_C(0x000fffffffffffff),
 UINT64_C(0x0123456789abcdef),UINT64_C(0xfedcba9876543210)};
int main(int argc,char **argv) {
 unsigned fault=argc==2?(unsigned)strtoul(argv[1],0,10):0;
 if(argc>2||fault>5) return 2;
 unsigned observations=0;
 for(unsigned i=0;i!=16;++i) for(unsigned j=0;j!=16;++j) {
  uint64_t a=payloads[i],b=payloads[j];
  uint32_t af=(uint32_t)(a^(a>>32)),bf=(uint32_t)(b^(b>>32));
  float fa,fb,fr; double da,db,dr;
  memcpy(&fa,&af,4);memcpy(&fb,&bf,4);memcpy(&da,&a,8);memcpy(&db,&b,8);
  for(unsigned which=0;which!=10;++which) {
   u128 actual,expected;
   switch(which) {
    case 0:actual=values_bswap32(af);expected=swap(af,4);break;
    case 1:actual=values_bswap64(a);expected=swap(a,8);break;
    case 2: {
     uint32_t raw;fr=values_copysign32(fa,fb);memcpy(&raw,&fr,4);
     actual=raw;expected=(af&UINT32_C(0x7fffffff))|(bf&UINT32_C(0x80000000));break;
    }
    case 3: {
     uint64_t raw;dr=values_copysign64(da,db);memcpy(&raw,&dr,8);
     actual=raw;expected=(a&UINT64_C(0x7fffffffffffffff))|(b&UINT64_C(0x8000000000000000));break;
    }
    case 4: {
     u128 value=((u128)a<<64)|b;_Bool choose=(i+j)&1;
     actual=values_zero_return(value,choose);expected=choose?value:0;break;
    }
    case 5:actual=values_wide_literal();expected=(u128)1<<64;break;
    case 6:case 7: {
     uint8_t input=(uint8_t)(i*16+j);unsigned narrow=input&7;
     int signed_value=(narrow&4)?(int)narrow-8:(int)narrow;
     double value=which==6?(double)signed_value:(double)narrow;uint64_t bits;
     memcpy(&bits,&value,8);expected=bits;
     actual=which==6?values_signed3(input):values_unsigned3(input);break;
    }
    case 8:
     actual=values_srem32_call(af,b);
     expected=(uint64_t)(int64_t)((int32_t)af%64)^(uint64_t)af^b;break;
    default:
     actual=values_srem32_plain(af);expected=(uint32_t)((int32_t)af%64);break;
   }
   if(fault==1&&which<2) actual^=1;
   if(fault==2&&(which==2||which==3)) actual^=(u128)1<<(which==2?31:63);
   if(fault==3&&(which==4||which==5)) actual^=(u128)1<<80;
   if(fault==4&&(which==6||which==7)) actual^=1;
   if(fault==5&&which>=8) actual^=1;
   if(actual!=expected) {
    fprintf(stderr,"preopt-values case=%u i=%u j=%u fault=%u observation=%u\n",which,i,j,fault,observations);
    return 1;
   }
   ++observations;
  }
 }
 printf("preopt-values observations=%u independent-c-bit-goldens=byte-swaps=fp-payloads=wide-returns=narrow-conversions=signed-remainders=live-values=preserved\n",observations);
 return 0;
}
