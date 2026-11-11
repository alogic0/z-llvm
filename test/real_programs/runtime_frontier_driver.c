#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef unsigned __int128 u128;
typedef float packed_float __attribute__((vector_size(8)));
extern u128 runtime_frontier_cttz(u128);
extern u128 runtime_frontier_min(u128,u128), runtime_frontier_max(u128,u128);
extern u128 runtime_frontier_funnel_0(u128,u128), runtime_frontier_funnel_1(u128,u128);
extern u128 runtime_frontier_funnel_63(u128,u128), runtime_frontier_funnel_64(u128,u128);
extern u128 runtime_frontier_funnel_65(u128,u128), runtime_frontier_funnel_127(u128,u128);
extern uint64_t runtime_frontier_pairs(uint64_t,uint64_t,uint64_t,uint64_t,void *,uint64_t);
extern uint64_t runtime_frontier_div(uint64_t,uint64_t,uint64_t,void *,uint64_t);
extern int runtime_frontier_ucmp(uint64_t,uint64_t), runtime_frontier_scmp(int64_t,int64_t);
extern int runtime_frontier_ucmp32(uint32_t,uint32_t);
extern uint16_t runtime_frontier_half(float,float,float,float);
extern uint16_t runtime_frontier_sign(uint16_t,uint16_t), runtime_frontier_halfmax(uint16_t,uint16_t);
extern double runtime_frontier_shuffle(double,double,double,double,void *,double);
extern packed_float runtime_frontier_packed(float,float);
extern uint64_t runtime_frontier_packed_call(float,float);
extern void runtime_frontier_quad(__float128,__float128,__float128,__float128,void *);
extern long double runtime_frontier_max80(long double,long double);
extern __float128 runtime_frontier_max128(__float128,__float128);
extern void runtime_frontier_byval(void *,long double,long double,long double,long double);
extern void runtime_frontier_byval_call(void *,const void *,const void *,const void *,const void *);
extern uint64_t runtime_frontier_weak(uint64_t), runtime_frontier_weak_data;
static double fp64(uint64_t bits) { double x; memcpy(&x,&bits,8); return x; }
static float fp32(uint32_t bits) { float x; memcpy(&x,&bits,4); return x; }
static uint64_t bits64(double x) { uint64_t bits; memcpy(&bits,&x,8); return bits; }
static uint64_t word(const void *p) { uint64_t x; memcpy(&x,p,8); return x; }
static uint16_t halfbits(_Float16 x) { uint16_t bits; memcpy(&bits,&x,2); return bits; }
int main(int argc,char **argv) {
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;
 size_t observations=0;
#define CHECK(c) do { ++observations; if (!(c)) { fprintf(stderr,"runtime-frontier line=%d observation=%zu fault=%u\n",__LINE__,observations,fault); return 1; } } while (0)
 const uint64_t values[]={0,1,UINT64_MAX,UINT64_C(0x8000000000000000),UINT64_C(0x0123456789abcdef)};
 u128 (*funnels[])(u128,u128)={runtime_frontier_funnel_0,runtime_frontier_funnel_1,runtime_frontier_funnel_63,runtime_frontier_funnel_64,runtime_frontier_funnel_65,runtime_frontier_funnel_127};
 const unsigned shifts[]={0,1,63,64,65,127};
 for(unsigned i=0;i<5;++i) for(unsigned j=0;j<5;++j) {
  uint64_t a=values[i], b=values[j], c=a^UINT64_C(0x9988776655443322), d=b+127;
  u128 left=((u128)b<<64)|a, right=((u128)a<<64)|b;
  unsigned count=128; for(unsigned bit=0;bit<128;++bit) if ((left>>bit)&1) {count=bit;break;}
  CHECK((runtime_frontier_cttz(left)^(fault==1))==count);
  CHECK(runtime_frontier_min(left,right)==(left<right?left:right));
  CHECK(runtime_frontier_max(left,right)==(left>right?left:right));
  for(unsigned k=0;k<6;++k) CHECK(funnels[k](left,right)==(shifts[k]?(left<<shifts[k])|(right>>(128-shifts[k])):left));
  CHECK(runtime_frontier_ucmp(a,b)==(a<b?-1:a>b?1:0));
  CHECK(runtime_frontier_scmp((int64_t)a,(int64_t)b)==((int64_t)a<(int64_t)b?-1:(int64_t)a>(int64_t)b?1:0));
  CHECK(runtime_frontier_ucmp32((uint32_t)a,(uint32_t)b)==((uint32_t)a<(uint32_t)b?-1:(uint32_t)a>(uint32_t)b?1:0));
  unsigned char out[48]; memset(out,0xa5,sizeof out);
  CHECK(runtime_frontier_pairs(a,b,c,d,out+8,a+b)==(a^c^(a+b)));
  CHECK(word(out+8)==(a^c)); CHECK(word(out+16)==(b^d));
  CHECK(word(out)==UINT64_C(0xa5a5a5a5a5a5a5a5)); CHECK(word(out+24)==UINT64_C(0xa5a5a5a5a5a5a5a5));
  uint64_t divisor=b?b:1, high=a%divisor;
  u128 numerator=((u128)high<<64)|a;
  CHECK(runtime_frontier_div(divisor,a,high,out+8,b)==((uint64_t)(numerator/divisor)^b));
  CHECK(word(out+8)==numerator/divisor); CHECK(word(out+16)==numerator%divisor);
  CHECK(word(out)==UINT64_C(0xa5a5a5a5a5a5a5a5)); CHECK(word(out+24)==UINT64_C(0xa5a5a5a5a5a5a5a5));
  uint64_t c_bits=a^UINT64_C(0x8000000000000000), d_bits=b^UINT64_C(0x8000000000000000);
  CHECK(bits64(runtime_frontier_shuffle(fp64(a),fp64(b),fp64(c_bits),fp64(d_bits),out+8,fp64(a)))==a);
  CHECK(word(out+8)==d_bits); CHECK(word(out+16)==a); CHECK(word(out+24)==c_bits); CHECK(word(out+32)==b);
  CHECK(word(out)==UINT64_C(0xa5a5a5a5a5a5a5a5)); CHECK(word(out+40)==UINT64_C(0xa5a5a5a5a5a5a5a5));
  uint64_t packed=(uint32_t)a|((uint64_t)(uint32_t)b<<32), actual;
  packed_float v=runtime_frontier_packed(fp32(a),fp32(b)); memcpy(&actual,&v,8);
  CHECK((actual^(fault==2))==packed); CHECK(runtime_frontier_packed_call(fp32(a),fp32(b))==packed);
  uint16_t ha=(uint16_t)a,hb=(uint16_t)b;
  CHECK(runtime_frontier_sign(ha,hb)==((ha&0x7fff)|(hb&0x8000)));
 }
 for(unsigned i=0;i<8;++i) {
  float a=(float)i-3.f,b=0.5f,c=2.f,d=(float)i;
  _Float16 expected=(_Float16)((_Float16)(a*b)+(_Float16)(c*d));
  CHECK((runtime_frontier_half(a,b,c,d)^(fault==3))==halfbits(expected));
  CHECK(runtime_frontier_halfmax(halfbits((_Float16)a),halfbits((_Float16)c))==halfbits((_Float16)(a>c?a:c)));
  CHECK(runtime_frontier_max80((long double)a,2.L)==(a>2.f?a:2.f));
  CHECK(runtime_frontier_max128((__float128)a,2.Q)==(a>2.f?a:2.f));
 }
 struct { uint64_t before[2]; __float128 lane[4]; uint64_t after[2]; } quad;
 memset(&quad,0xa5,sizeof quad);
 runtime_frontier_quad(1.Q,-2.Q,3.Q,-4.Q,quad.lane);
 CHECK(quad.lane[0]==-4.Q); CHECK(quad.lane[1]==1.Q); CHECK(quad.lane[2]==3.Q); CHECK(quad.lane[3]==-2.Q);
 CHECK(quad.before[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)); CHECK(quad.after[0]==UINT64_C(0xa5a5a5a5a5a5a5a5));
 CHECK(runtime_frontier_weak(7654321)==(7654321^1234567)); CHECK(runtime_frontier_weak_data==1234567);
 long double extended[4]={1.L,-2.L,3.L,-4.L};
 unsigned char x87[80]; memset(x87,0xa5,sizeof x87);
 runtime_frontier_byval(x87+8,extended[0],extended[1],extended[2],extended[3]);
 for(unsigned i=0;i<4;++i) CHECK(memcmp(x87+8+i*16,&extended[i],10)==0);
 CHECK(word(x87)==UINT64_C(0xa5a5a5a5a5a5a5a5)); CHECK(word(x87+72)==UINT64_C(0xa5a5a5a5a5a5a5a5));
 runtime_frontier_byval_call(x87+8,extended,extended+1,extended+2,extended+3);
 for(unsigned i=0;i<4;++i) CHECK(memcmp(x87+8+i*16,&extended[i],10)==0);
 CHECK(word(x87)==UINT64_C(0xa5a5a5a5a5a5a5a5)); CHECK(word(x87+72)==UINT64_C(0xa5a5a5a5a5a5a5a5));
 printf("runtime-frontier observations=%zu pairs=intrinsics=vectors=half=aliases=preserved\n",observations);
 return 0;
}
