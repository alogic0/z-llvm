#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
extern uint64_t client_default_i64(uint64_t,uint64_t);
extern uint64_t client_pointer(const uint64_t *,uint64_t);
extern uint64_t client_live(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t *);
extern uint64_t client_literal(uint64_t,uint64_t);
extern uint64_t client_stack(uint64_t,uint64_t);
extern uint64_t client_flags(uint64_t,uint64_t,uint64_t);
void client_fill(uint64_t *p,uint64_t seed) { for(unsigned i=0;i<6;i++) p[i]=seed+i*13; }
int main(int argc,char **argv) {
 unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
 size_t observations=0;
#define CHECK(c) do { ++observations; if(!(c)) { fprintf(stderr,"client-requests fault=%u observation=%zu\n",fault,observations); return 1; } } while(0)
 for(unsigned seed=0;seed<64;seed++) {
  struct { uint64_t pre[2],request[6],post[2]; } req;
  struct { uint64_t pre[2],value,post[2]; } out;
  memset(&req,0xa5,sizeof(req)); memset(&out,0xa5,sizeof(out));
  client_fill(req.request,seed*31);
  uint64_t a=UINT64_C(0x9e3779b97f4a7c15)*seed,b=a^UINT64_C(0xdeadbeefcafebabe);
  uint64_t c=a+17,d=b+31,e=~a,f=~b,g=(a<<19)^b,h=a*7+b;
  uint64_t actual=client_default_i64(a,h);
  if(fault==1) actual^=1;
  CHECK(actual==h);
  CHECK(client_pointer(req.request,h)==h);
  uint64_t expected=h+a+b+c+d+e+f+g+h;
  CHECK(client_live(a,b,c,d,e,f,g,h,&out.value)==expected);
  CHECK(out.value==expected);
  CHECK(client_literal(a,b)==(UINT64_C(18369614221190020847)^b));
  CHECK(client_stack(a,h)==(a^h));
  CHECK(client_flags(a,b,h)==((int64_t)a<(int64_t)b ? h+7 : h^13));
  if(fault==2) req.pre[0]^=1;
  if(fault==3) out.post[1]^=1;
  CHECK(req.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&req.pre[1]==req.pre[0]&&req.post[0]==req.pre[0]&&req.post[1]==req.pre[0]);
  CHECK(out.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.pre[1]==out.pre[0]);
  CHECK(out.post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.post[1]==out.post[0]);
 }
 printf("client-requests observations=%zu magic=defaults=pointers=live-values=flags=guards=preserved\n",observations);
 return 0;
}
