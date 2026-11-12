#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
extern uint64_t constant_cmp_8(uint64_t *,uint64_t);
extern uint64_t constant_cmp_16(uint64_t *,uint64_t);
extern uint64_t constant_cmp_32(uint64_t *,uint64_t);
extern uint64_t constant_cmp_64(uint64_t *,uint64_t);
static uint64_t expected(unsigned width) {
 uint64_t high=UINT64_C(1)<<(width-1),mask=width==64 ? UINT64_MAX : (high<<1)-1;
 uint64_t pairs[3][2]={{high,3},{mask,mask},{65,65}},result=0;
 unsigned bit=0;
 for(unsigned j=0;j<3;j++) {
  uint64_t a=pairs[j][0]&mask,b=pairs[j][1]&mask;
  int64_t sa=width==64 ? (int64_t)a : (int64_t)(a^high)-(int64_t)high;
  int64_t sb=width==64 ? (int64_t)b : (int64_t)(b^high)-(int64_t)high;
  unsigned flags[]={a==b,a!=b,sa<sb,sa<=sb,sa>sb,sa>=sb,a<b,a<=b,a>b,a>=b};
  for(unsigned i=0;i<10;i++) result|=(uint64_t)flags[i]<<bit++;
 }
 return result;
}
int main(int argc,char **argv) {
 unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
 size_t observations=0;
#define CHECK(c) do { ++observations; if(!(c)) { fprintf(stderr,"constant-compares fault=%u observation=%zu\n",fault,observations); return 1; } } while(0)
 uint64_t (*functions[4])(uint64_t *,uint64_t)={constant_cmp_8,constant_cmp_16,constant_cmp_32,constant_cmp_64};
 const unsigned widths[4]={8,16,32,64};
 for(unsigned seed=0;seed<64;seed++) for(unsigned i=0;i<4;i++) {
  struct { uint64_t pre[2],value,post[2]; } out;
  memset(&out,0xa5,sizeof(out));
  uint64_t live=seed*UINT64_C(0x9e3779b97f4a7c15),want=expected(widths[i])^live;
  uint64_t got=functions[i](&out.value,live);
  if(fault==1) got^=1;
  if(fault==2) out.pre[0]^=1;
  if(fault==3) out.post[1]^=1;
  CHECK(got==want); CHECK(out.value==want);
  CHECK(out.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.pre[1]==out.pre[0]);
  CHECK(out.post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.post[1]==out.post[0]);
 }
 printf("constant-compares observations=%zu predicates=widths=sign-bits=live-inputs=guards=preserved\n",observations);
 return 0;
}
